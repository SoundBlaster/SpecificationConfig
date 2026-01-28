import Configuration
@testable import SpecificationConfig
import XCTest

final class PerformanceBenchmarkTests: XCTestCase {
    // MARK: - Pipeline Build

    func testPipelineBuildPerformanceWith100Bindings() {
        // Create 100 bindings using generated keypaths
        let bindings: [AnyBinding<LargeDraft>] = LargeDraft.keyPaths.enumerated().map { index, keyPath in
            AnyBinding(Binding(
                key: "key.\(index)",
                keyPath: keyPath,
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

// swiftlint:disable line_length
private struct LargeDraft {
    var v0: String?; var v1: String?; var v2: String?; var v3: String?; var v4: String?
    var v5: String?; var v6: String?; var v7: String?; var v8: String?; var v9: String?
    var v10: String?; var v11: String?; var v12: String?; var v13: String?; var v14: String?
    var v15: String?; var v16: String?; var v17: String?; var v18: String?; var v19: String?
    var v20: String?; var v21: String?; var v22: String?; var v23: String?; var v24: String?
    var v25: String?; var v26: String?; var v27: String?; var v28: String?; var v29: String?
    var v30: String?; var v31: String?; var v32: String?; var v33: String?; var v34: String?
    var v35: String?; var v36: String?; var v37: String?; var v38: String?; var v39: String?
    var v40: String?; var v41: String?; var v42: String?; var v43: String?; var v44: String?
    var v45: String?; var v46: String?; var v47: String?; var v48: String?; var v49: String?
    var v50: String?; var v51: String?; var v52: String?; var v53: String?; var v54: String?
    var v55: String?; var v56: String?; var v57: String?; var v58: String?; var v59: String?
    var v60: String?; var v61: String?; var v62: String?; var v63: String?; var v64: String?
    var v65: String?; var v66: String?; var v67: String?; var v68: String?; var v69: String?
    var v70: String?; var v71: String?; var v72: String?; var v73: String?; var v74: String?
    var v75: String?; var v76: String?; var v77: String?; var v78: String?; var v79: String?
    var v80: String?; var v81: String?; var v82: String?; var v83: String?; var v84: String?
    var v85: String?; var v86: String?; var v87: String?; var v88: String?; var v89: String?
    var v90: String?; var v91: String?; var v92: String?; var v93: String?; var v94: String?
    var v95: String?; var v96: String?; var v97: String?; var v98: String?; var v99: String?

    nonisolated(unsafe) static let keyPaths: [WritableKeyPath<LargeDraft, String?>] = [
        \.v0, \.v1, \.v2, \.v3, \.v4, \.v5, \.v6, \.v7, \.v8, \.v9,
        \.v10, \.v11, \.v12, \.v13, \.v14, \.v15, \.v16, \.v17, \.v18, \.v19,
        \.v20, \.v21, \.v22, \.v23, \.v24, \.v25, \.v26, \.v27, \.v28, \.v29,
        \.v30, \.v31, \.v32, \.v33, \.v34, \.v35, \.v36, \.v37, \.v38, \.v39,
        \.v40, \.v41, \.v42, \.v43, \.v44, \.v45, \.v46, \.v47, \.v48, \.v49,
        \.v50, \.v51, \.v52, \.v53, \.v54, \.v55, \.v56, \.v57, \.v58, \.v59,
        \.v60, \.v61, \.v62, \.v63, \.v64, \.v65, \.v66, \.v67, \.v68, \.v69,
        \.v70, \.v71, \.v72, \.v73, \.v74, \.v75, \.v76, \.v77, \.v78, \.v79,
        \.v80, \.v81, \.v82, \.v83, \.v84, \.v85, \.v86, \.v87, \.v88, \.v89,
        \.v90, \.v91, \.v92, \.v93, \.v94, \.v95, \.v96, \.v97, \.v98, \.v99,
    ]
}

// swiftlint:enable line_length

private struct SmallDraft {
    var name: String?
    var derived: String?
}
