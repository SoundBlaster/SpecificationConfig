import Configuration
@testable import SpecificationConfig
import XCTest

final class PerformanceBenchmarkTests: XCTestCase {
    // MARK: - Pipeline Build

    func testPipelineBuildPerformanceWith100Bindings() {
        let bindings: [AnyBinding<LargeDraft>] = (0 ..< 100).map { i in
            AnyBinding(Binding(
                key: "key.\(i)",
                keyPath: \LargeDraft.values[i],
                decoder: ConfigReader.string
            ))
        }
        let profile = SpecProfile<LargeDraft, LargeDraft>(
            bindings: bindings,
            finalize: { $0 },
            makeDraft: { LargeDraft() }
        )
        var values: [AbsoluteConfigKey: ConfigValue] = [:]
        for i in 0 ..< 100 {
            values[AbsoluteConfigKey(stringLiteral: "key.\(i)")] = ConfigValue(stringLiteral: "value_\(i)")
        }
        let reader = ConfigReader(provider: InMemoryProvider(values: values))

        measure {
            _ = ConfigPipeline.build(profile: profile, reader: reader)
        }
    }

    // MARK: - Async Pipeline Build

    func testPipelineBuildAsyncPerformance() async {
        let bindings: [AnyBinding<SmallDraft>] = [
            AnyBinding(Binding(
                key: "name",
                keyPath: \SmallDraft.name,
                decoder: ConfigReader.string
            )),
        ]
        let asyncDecisions: [AnyAsyncDecisionBinding<SmallDraft>] = [
            AnyAsyncDecisionBinding(AsyncDecisionBinding(
                key: "derived",
                keyPath: \SmallDraft.derived,
                decisions: [
                    AsyncDecisionEntry(
                        description: "default",
                        predicate: { _ async in true },
                        result: "computed"
                    ),
                ]
            )),
        ]
        let profile = SpecProfile<SmallDraft, SmallDraft>(
            bindings: bindings,
            asyncDecisionBindings: asyncDecisions,
            finalize: { $0 },
            makeDraft: { SmallDraft() }
        )
        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "name": "test",
        ]))

        let clock = ContinuousClock()
        let iterations = 100
        let elapsed = await clock.measure {
            for _ in 0 ..< iterations {
                _ = await ConfigPipeline.buildAsync(profile: profile, reader: reader)
            }
        }
        let perIteration = elapsed / iterations
        // Sanity check: each async build should complete in under 10ms
        XCTAssertLessThan(perIteration, .milliseconds(10), "Async build took \(perIteration) per iteration")
    }

    // MARK: - Snapshot Lookup

    func testSnapshotValueLookupPerformance() {
        let resolvedValues: [ResolvedValue] = (0 ..< 500).map { i in
            ResolvedValue(
                key: "key.\(i)",
                stringifiedValue: "value_\(i)",
                provenance: .defaultValue
            )
        }
        let snapshot = Snapshot(
            resolvedValues: resolvedValues,
            diagnostics: DiagnosticsReport()
        )

        measure {
            for i in 0 ..< 500 {
                _ = snapshot.value(forKey: "key.\(i)")
            }
        }
    }

    // MARK: - Snapshot Diff

    func testSnapshotDiffPerformance() {
        let oldValues: [ResolvedValue] = (0 ..< 200).map { i in
            ResolvedValue(
                key: "key.\(i)",
                stringifiedValue: "old_\(i)",
                provenance: .defaultValue
            )
        }
        let newValues: [ResolvedValue] = (0 ..< 200).map { i in
            ResolvedValue(
                key: "key.\(i)",
                stringifiedValue: i % 3 == 0 ? "changed_\(i)" : "old_\(i)",
                provenance: .defaultValue
            )
        }
        let oldSnapshot = Snapshot(
            resolvedValues: oldValues,
            diagnostics: DiagnosticsReport()
        )
        let newSnapshot = Snapshot(
            resolvedValues: newValues,
            diagnostics: DiagnosticsReport()
        )

        measure {
            _ = newSnapshot.diff(from: oldSnapshot)
        }
    }

    // MARK: - Schema Validation

    func testSchemaValidationPerformance() {
        let requirements: [ConfigSchema.KeyRequirement] = (0 ..< 200).map { i in
            .required("key.\(i)", check: .string)
        }
        let schema = ConfigSchema(requirements: requirements)

        var values: [AbsoluteConfigKey: ConfigValue] = [:]
        for i in 0 ..< 200 {
            values[AbsoluteConfigKey(stringLiteral: "key.\(i)")] = ConfigValue(stringLiteral: "v\(i)")
        }
        let reader = ConfigReader(provider: InMemoryProvider(values: values))

        measure {
            _ = schema.validate(reader: reader)
        }
    }
}

// MARK: - Test Helpers

private struct LargeDraft {
    var values: [String?] = Array(repeating: nil, count: 100)
}

private struct SmallDraft {
    var name: String?
    var derived: String?
}
