import Configuration
@testable import SpecificationConfig
import XCTest

final class PerformanceMetricsTests: XCTestCase {
    // MARK: - Sync Pipeline Metrics

    func testSyncBuildCapturesBindingDurations() {
        struct Draft {
            var name: String?
            var port: Int?
        }

        struct Config {
            let name: String
            let port: Int
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "app.name",
                    keyPath: \Draft.name,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
                AnyBinding(Binding(
                    key: "app.port",
                    keyPath: \Draft.port,
                    decoder: ConfigReader.int
                )),
            ],
            finalize: { Config(name: $0.name ?? "", port: $0.port ?? 0) },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "app.name": "Test",
            "app.port": 8080,
        ]))

        let result = ConfigPipeline.build(profile: profile, reader: reader)
        let metrics = try XCTUnwrap(result.snapshot.performanceMetrics)

        XCTAssertEqual(metrics.bindingDurations.count, 2)
        XCTAssertNotNil(metrics.bindingDurations["app.name"])
        XCTAssertNotNil(metrics.bindingDurations["app.port"])
        XCTAssertTrue(metrics.totalDuration > .zero)
        XCTAssertTrue(metrics.finalizationDuration >= .zero)
    }

    func testSyncBuildCapturesDecisionBindingDurations() {
        struct Draft {
            var mode: String?
            var label: String?
        }

        struct Config {
            let mode: String
            let label: String
        }

        let decision = DecisionEntry<Draft, String>(
            description: "Label from mode"
        ) { draft in
            draft.mode == "dark" ? "Dark Mode" : nil
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "mode",
                    keyPath: \Draft.mode,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
            ],
            decisionBindings: [
                AnyDecisionBinding(DecisionBinding(
                    key: "label",
                    keyPath: \Draft.label,
                    decisions: [decision]
                )),
            ],
            finalize: { Config(mode: $0.mode ?? "", label: $0.label ?? "") },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "mode": "dark",
        ]))

        let result = ConfigPipeline.build(profile: profile, reader: reader)
        let metrics = try XCTUnwrap(result.snapshot.performanceMetrics)

        XCTAssertEqual(metrics.decisionBindingDurations.count, 1)
        XCTAssertNotNil(metrics.decisionBindingDurations["label"])
    }

    func testSyncBuildMetricsOnFailure() {
        struct Draft {
            var value: String?
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "missing",
                    keyPath: \Draft.value,
                    decoder: { _, _ -> String? in throw ConfigError.decodeFailed(key: "missing", underlyingError: "not found") }
                )),
            ],
            finalize: { $0.value ?? "" },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [:]))

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .failure(_, snapshot):
            let metrics = try XCTUnwrap(snapshot.performanceMetrics)
            XCTAssertEqual(metrics.bindingDurations.count, 1)
            XCTAssertNotNil(metrics.bindingDurations["missing"])
            XCTAssertTrue(metrics.totalDuration > .zero)
        case .success:
            XCTFail("Expected failure")
        }
    }

    // MARK: - Async Pipeline Metrics

    func testAsyncBuildCapturesMetrics() async {
        struct Draft {
            var name: String?
        }

        struct Config {
            let name: String
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "name",
                    keyPath: \Draft.name,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
            ],
            finalize: { Config(name: $0.name ?? "") },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "name": "AsyncTest",
        ]))

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)
        let metrics = try XCTUnwrap(result.snapshot.performanceMetrics)

        XCTAssertEqual(metrics.bindingDurations.count, 1)
        XCTAssertNotNil(metrics.bindingDurations["name"])
        XCTAssertTrue(metrics.totalDuration > .zero)
    }

    func testAsyncBuildCapturesAsyncDecisionDurations() async {
        struct Draft: Sendable {
            var mode: String?
            var label: String?
        }

        struct Config: Sendable {
            let mode: String
            let label: String
        }

        let asyncDecision = AsyncDecisionEntry<Draft, String>(
            description: "Derive label"
        ) { draft in
            draft.mode == "light" ? "Light Mode" : nil
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "mode",
                    keyPath: \Draft.mode,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
            ],
            asyncDecisionBindings: [
                AnyAsyncDecisionBinding(AsyncDecisionBinding(
                    key: "label",
                    keyPath: \Draft.label,
                    decisions: [asyncDecision]
                )),
            ],
            finalize: { Config(mode: $0.mode ?? "", label: $0.label ?? "") },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "mode": "light",
        ]))

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)
        let metrics = try XCTUnwrap(result.snapshot.performanceMetrics)

        XCTAssertEqual(metrics.decisionBindingDurations.count, 1)
        XCTAssertNotNil(metrics.decisionBindingDurations["label"])
    }

    // MARK: - Snapshot Without Metrics

    func testSnapshotWithoutMetricsIsNil() {
        let snapshot = Snapshot()
        XCTAssertNil(snapshot.performanceMetrics)
    }

    func testTotalDurationIncludesAllPhases() {
        struct Draft {
            var a: String?
            var b: String?
        }

        let profile = SpecProfile(
            bindings: [
                AnyBinding(Binding(
                    key: "a",
                    keyPath: \Draft.a,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
                AnyBinding(Binding(
                    key: "b",
                    keyPath: \Draft.b,
                    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
                )),
            ],
            finalize: { "\($0.a ?? "")-\($0.b ?? "")" },
            makeDraft: { Draft() }
        )

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "a": "x",
            "b": "y",
        ]))

        let result = ConfigPipeline.build(profile: profile, reader: reader)
        let metrics = try XCTUnwrap(result.snapshot.performanceMetrics)

        // Total should be >= sum of binding + finalization durations
        let bindingSum = metrics.bindingDurations.values.reduce(Duration.zero, +)
        let componentSum = bindingSum + metrics.finalizationDuration
        XCTAssertTrue(metrics.totalDuration >= componentSum)
    }
}
