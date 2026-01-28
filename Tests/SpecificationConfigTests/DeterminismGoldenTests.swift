@testable import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

/// Golden tests proving deterministic error ordering across multiple runs
/// with complex scenarios (50+ bindings).
final class DeterminismGoldenTests: XCTestCase {
    // MARK: - Draft / Config Types

    struct LargeDraft {
        var field00: String?
        var field01: String?
        var field02: String?
        var field03: String?
        var field04: String?
        var field05: String?
        var field06: String?
        var field07: String?
        var field08: String?
        var field09: String?
        var field10: String?
        var field11: String?
        var field12: String?
        var field13: String?
        var field14: String?
        var field15: String?
        var field16: String?
        var field17: String?
        var field18: String?
        var field19: String?
        var field20: Int?
        var field21: Int?
        var field22: Int?
        var field23: Int?
        var field24: Int?
        var field25: Bool?
        var field26: Bool?
        var field27: Bool?
        var field28: Bool?
        var field29: Bool?
        var field30: String?
        var field31: String?
        var field32: String?
        var field33: String?
        var field34: String?
        var field35: String?
        var field36: String?
        var field37: String?
        var field38: String?
        var field39: String?
        var field40: String?
        var field41: String?
        var field42: String?
        var field43: String?
        var field44: String?
        var field45: String?
        var field46: String?
        var field47: String?
        var field48: String?
        var field49: String?
    }

    struct LargeConfig {
        let value: String
    }

    // MARK: - Helpers

    /// Builds a profile with 50 string bindings where every odd-indexed one has a failing spec.
    /// This produces a mix of successful and failing bindings with deterministic keys.
    private func buildLargeProfile() -> SpecProfile<LargeDraft, LargeConfig> {
        let failSpec = SpecEntry<String>(description: "Must not be empty") { value in
            !value.isEmpty
        }

        // Create 50 bindings with alternating success/failure specs
        let keyPaths: [WritableKeyPath<LargeDraft, String?>] = [
            \.field00, \.field01, \.field02, \.field03, \.field04,
            \.field05, \.field06, \.field07, \.field08, \.field09,
            \.field10, \.field11, \.field12, \.field13, \.field14,
            \.field15, \.field16, \.field17, \.field18, \.field19,
            \.field30, \.field31, \.field32, \.field33, \.field34,
            \.field35, \.field36, \.field37, \.field38, \.field39,
            \.field40, \.field41, \.field42, \.field43, \.field44,
            \.field45, \.field46, \.field47, \.field48, \.field49,
        ]

        var bindings: [AnyBinding<LargeDraft>] = []

        for i in 0 ..< 40 {
            let key = String(format: "key.%02d", i)
            let binding = Binding(
                key: key,
                keyPath: keyPaths[i],
                decoder: { reader, k in reader.string(forKey: ConfigKey(k)) },
                valueSpecs: i % 2 == 1 ? [failSpec] : []
            )
            bindings.append(AnyBinding(binding))
        }

        // Add 10 int/bool bindings (indices 40-49)
        let intKeyPaths: [WritableKeyPath<LargeDraft, Int?>] = [
            \.field20, \.field21, \.field22, \.field23, \.field24,
        ]
        for i in 0 ..< 5 {
            let key = String(format: "key.%02d", 40 + i)
            let binding = Binding(
                key: key,
                keyPath: intKeyPaths[i],
                decoder: ConfigReader.int
            )
            bindings.append(AnyBinding(binding))
        }

        let boolKeyPaths: [WritableKeyPath<LargeDraft, Bool?>] = [
            \.field25, \.field26, \.field27, \.field28, \.field29,
        ]
        for i in 0 ..< 5 {
            let key = String(format: "key.%02d", 45 + i)
            let binding = Binding(
                key: key,
                keyPath: boolKeyPaths[i],
                decoder: ConfigReader.bool
            )
            bindings.append(AnyBinding(binding))
        }

        return SpecProfile(
            bindings: bindings,
            finalize: { _ in LargeConfig(value: "unused") },
            makeDraft: { LargeDraft() }
        )
    }

    /// Build a provider with all 50 keys; odd string keys get empty values to trigger spec failures.
    private func buildProvider() -> InMemoryProvider {
        var values: [AbsoluteConfigKey: ConfigValue] = [:]

        for i in 0 ..< 40 {
            let key = AbsoluteConfigKey(stringLiteral: String(format: "key.%02d", i))
            let str = i % 2 == 1 ? "" : "value-\(i)"
            values[key] = ConfigValue(stringLiteral: str)
        }
        for i in 40 ..< 45 {
            let key = AbsoluteConfigKey(stringLiteral: String(format: "key.%02d", i))
            values[key] = ConfigValue(integerLiteral: i)
        }
        for i in 45 ..< 50 {
            let key = AbsoluteConfigKey(stringLiteral: String(format: "key.%02d", i))
            values[key] = ConfigValue(booleanLiteral: i % 2 == 0)
        }

        return InMemoryProvider(values: values)
    }

    // MARK: - Golden Test: 50 bindings, 10 iterations, exact equality

    func testDeterministicOrderingWith50BindingsAcross10Runs() {
        let profile = buildLargeProfile()
        let provider = buildProvider()
        let reader = ConfigReader(provider: provider)

        // Run the pipeline 10 times and collect diagnostics messages
        var allRuns: [[String]] = []

        for _ in 0 ..< 10 {
            let result = ConfigPipeline.build(
                profile: profile,
                reader: reader,
                errorHandlingMode: .collectAll
            )

            switch result {
            case .success:
                XCTFail("Expected failures from empty-value spec violations")
                return
            case let .failure(diagnostics, _):
                let messages = diagnostics.diagnostics.map { item in
                    "\(item.key ?? "nil")|\(item.severity)|\(item.message)"
                }
                allRuns.append(messages)
            }
        }

        // All 10 runs must produce identical error lists
        let reference = allRuns[0]
        XCTAssertFalse(reference.isEmpty, "Expected at least one diagnostic")

        for (index, run) in allRuns.enumerated() {
            XCTAssertEqual(
                run, reference,
                "Run \(index) produced different diagnostics from run 0"
            )
        }

        // Verify we got the expected number of errors (20 odd-indexed bindings should fail)
        XCTAssertEqual(reference.count, 20, "Expected 20 spec failures from odd-indexed bindings")
    }

    // MARK: - Golden Test: Key ordering is alphabetical

    func testDiagnosticsAreSortedByKeyAlphabetically() {
        let profile = buildLargeProfile()
        let provider = buildProvider()
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(
            profile: profile,
            reader: reader,
            errorHandlingMode: .collectAll
        )

        switch result {
        case .success:
            XCTFail("Expected failures")
        case let .failure(diagnostics, _):
            let keys = diagnostics.diagnostics.compactMap(\.key)
            let sortedKeys = keys.sorted()
            XCTAssertEqual(keys, sortedKeys, "Diagnostic keys must be in alphabetical order")
        }
    }

    // MARK: - Golden Test: Mixed severity ordering

    func testDeterministicOrderingWithMixedSeverities() {
        var report = DiagnosticsReport()

        // Add items in scrambled order
        report.add(key: "beta", severity: .warning, message: "Warning on beta")
        report.add(key: "alpha", severity: .error, message: "Error on alpha")
        report.add(key: "alpha", severity: .warning, message: "Warning on alpha")
        report.add(key: "gamma", severity: .error, message: "Error on gamma")
        report.add(key: "beta", severity: .error, message: "Error on beta")
        report.add(key: "alpha", severity: .error, message: "Another error on alpha")

        // Collect multiple times to prove determinism
        var allRuns: [[String]] = []
        for _ in 0 ..< 10 {
            let messages = report.diagnostics.map { item in
                "\(item.key ?? "nil")|\(item.severity)|\(item.message)"
            }
            allRuns.append(messages)
        }

        let reference = allRuns[0]
        for (index, run) in allRuns.enumerated() {
            XCTAssertEqual(run, reference, "Access \(index) produced different order")
        }

        // Verify expected order: alpha errors, alpha warning, beta error, beta warning, gamma error
        let expectedOrder = [
            "alpha|error|Another error on alpha",
            "alpha|error|Error on alpha",
            "alpha|warning|Warning on alpha",
            "beta|error|Error on beta",
            "beta|warning|Warning on beta",
            "gamma|error|Error on gamma",
        ]
        XCTAssertEqual(reference, expectedOrder)
    }
}
