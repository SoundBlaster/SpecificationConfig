import Configuration
@testable import SpecificationConfig
import XCTest

/// Thread-safety tests for concurrent access to provenance reporter
/// and concurrent pipeline builds. Run with --sanitize=thread for full coverage.
final class ConcurrencyTests: XCTestCase {
    // MARK: - Provenance Reporter Concurrent Access

    func testProvenanceReporterConcurrentReadsAndResets() async {
        let reporter = ResolvedValueProvenanceReporter()

        // Exercise concurrent reads and resets without deadlocking
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 100 {
                group.addTask {
                    _ = reporter.provenance(forKey: "key.\(i)")
                    _ = reporter.provenance(forKey: "key.\((i + 50) % 100)")
                }

                if i % 10 == 0 {
                    group.addTask {
                        reporter.reset()
                    }
                }
            }
        }

        // No deadlock or crash = success
    }

    // MARK: - Concurrent Pipeline Builds

    func testConcurrentSyncPipelineBuilds() async {
        struct Draft {
            var name: String?
            var port: Int?
        }

        struct Config: Equatable, Sendable {
            let name: String
            let port: Int
        }

        let nameBinding = Binding(
            key: "app.name",
            keyPath: \Draft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let portBinding = Binding(
            key: "app.port",
            keyPath: \Draft.port,
            decoder: ConfigReader.int
        )

        let profile = SendableBox(value: SpecProfile(
            bindings: [AnyBinding(nameBinding), AnyBinding(portBinding)],
            finalize: { draft in
                Config(name: draft.name ?? "default", port: draft.port ?? 0)
            },
            makeDraft: { Draft() }
        ))

        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
        ])
        let reader = ConfigReader(provider: provider)

        let collector = ResultCollector<Config>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 50 {
                group.addTask {
                    let result = ConfigPipeline.build(profile: profile.value, reader: reader)
                    switch result {
                    case let .success(config, _):
                        await collector.addSuccess(config)
                    case .failure:
                        await collector.addFailure()
                    }
                }
            }
        }

        let successes = await collector.successes
        let failures = await collector.failureCount

        XCTAssertEqual(successes.count, 50)
        XCTAssertEqual(failures, 0)
        for config in successes {
            XCTAssertEqual(config, Config(name: "TestApp", port: 8080))
        }
    }

    func testConcurrentAsyncPipelineWithDecisionBindings() async {
        struct Draft: Sendable {
            var mode: String?
            var label: String?
        }

        struct Config: Equatable, Sendable {
            let mode: String
            let label: String
        }

        let modeBinding = Binding(
            key: "app.mode",
            keyPath: \Draft.mode,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let asyncDecision = AsyncDecisionEntry<Draft, String>(
            description: "Derive label from mode"
        ) { draft in
            draft.mode == "dark" ? "Dark Mode" : nil
        }

        let asyncDecisionBinding = AsyncDecisionBinding(
            key: "app.label",
            keyPath: \Draft.label,
            decisions: [asyncDecision]
        )

        let profile = SendableBox(value: SpecProfile(
            bindings: [AnyBinding(modeBinding)],
            asyncDecisionBindings: [AnyAsyncDecisionBinding(asyncDecisionBinding)],
            finalize: { draft in
                Config(mode: draft.mode ?? "", label: draft.label ?? "default")
            },
            makeDraft: { Draft() }
        ))

        let provider = InMemoryProvider(values: [
            "app.mode": "dark",
        ])
        let reader = ConfigReader(provider: provider)

        let collector = ResultCollector<Config>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 30 {
                group.addTask {
                    let result = await ConfigPipeline.buildAsync(profile: profile.value, reader: reader)
                    switch result {
                    case let .success(config, _):
                        await collector.addSuccess(config)
                    case .failure:
                        await collector.addFailure()
                    }
                }
            }
        }

        let successes = await collector.successes
        let failures = await collector.failureCount

        XCTAssertEqual(successes.count, 30)
        XCTAssertEqual(failures, 0)
        for config in successes {
            XCTAssertEqual(config, Config(mode: "dark", label: "Dark Mode"))
        }
    }

    func testConcurrentMixedSyncAndAsyncBuilds() async {
        struct Draft: Sendable {
            var value: String?
        }

        struct Config: Equatable, Sendable {
            let value: String
        }

        let binding = Binding(
            key: "key",
            keyPath: \Draft.value,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let profile = SendableBox(value: SpecProfile(
            bindings: [AnyBinding(binding)],
            finalize: { Config(value: $0.value ?? "missing") },
            makeDraft: { Draft() }
        ))

        let provider = InMemoryProvider(values: ["key": "hello"])
        let reader = ConfigReader(provider: provider)

        let collector = ResultCollector<Config>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 40 {
                if i % 2 == 0 {
                    group.addTask {
                        let result = ConfigPipeline.build(profile: profile.value, reader: reader)
                        switch result {
                        case let .success(config, _): await collector.addSuccess(config)
                        case .failure: await collector.addFailure()
                        }
                    }
                } else {
                    group.addTask {
                        let result = await ConfigPipeline.buildAsync(profile: profile.value, reader: reader)
                        switch result {
                        case let .success(config, _): await collector.addSuccess(config)
                        case .failure: await collector.addFailure()
                        }
                    }
                }
            }
        }

        let successes = await collector.successes
        XCTAssertEqual(successes.count, 40)
        for config in successes {
            XCTAssertEqual(config, Config(value: "hello"))
        }
    }
}

/// Wraps a non-Sendable value for concurrent test contexts where the value
/// is created once and only read during concurrent execution.
private struct SendableBox<T>: @unchecked Sendable {
    let value: T
}

/// Actor to safely collect results from concurrent tasks.
private actor ResultCollector<T: Sendable> {
    var successes: [T] = []
    var failureCount = 0

    func addSuccess(_ value: T) {
        successes.append(value)
    }

    func addFailure() {
        failureCount += 1
    }
}
