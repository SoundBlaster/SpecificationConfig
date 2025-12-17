@testable import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

final class PipelineTests: XCTestCase {
    // MARK: - Test Types

    struct TestDraft {
        var name: String?
        var port: Int?
        var isEnabled: Bool?
    }

    struct TestConfig {
        let name: String
        let port: Int
        let isEnabled: Bool

        init(name: String, port: Int, isEnabled: Bool) {
            self.name = name
            self.port = port
            self.isEnabled = isEnabled
        }

        init(draft: TestDraft) throws {
            guard let name = draft.name else {
                throw TestError.missingName
            }
            guard let port = draft.port else {
                throw TestError.missingPort
            }
            self.name = name
            self.port = port
            isEnabled = draft.isEnabled ?? false
        }
    }

    enum TestError: Error {
        case missingName
        case missingPort
    }

    // MARK: - Happy Path Tests

    func testPipelineSuccessWithAllBindings() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )
        let portBinding = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) }
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding), AnyBinding(portBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config.name, "TestApp")
            XCTAssertEqual(config.port, 8080)
            XCTAssertEqual(config.isEnabled, false) // Default value
            XCTAssertFalse(snapshot.hasErrors)
            XCTAssertEqual(snapshot.resolvedValues.count, 2)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testPipelineSuccessWithDefaultValues() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "DefaultApp"
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                // Simple finalize that uses draft as-is
                guard let name = draft.name else {
                    throw TestError.missingName
                }
                return TestConfig(
                    name: name,
                    port: 3000,
                    isEnabled: false
                )
            },
            makeDraft: { TestDraft() }
        )

        // Empty provider - should use default
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(config, _):
            XCTAssertEqual(config.name, "DefaultApp")
        case .failure:
            XCTFail("Expected success with default value")
        }
    }

    // MARK: - Binding Failure Tests

    func testPipelineFailureOnBindingSpecViolation() {
        let positiveSpec = PredicateSpec<Int> { $0 > 0 }

        let portBinding = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [AnySpecification(positiveSpec)]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(portBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // Invalid port value (negative)
        let provider = InMemoryProvider(values: [
            "app.port": -1,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to spec violation")
        case let .failure(diagnostics, snapshot):
            XCTAssertTrue(diagnostics.hasErrors)
            XCTAssertEqual(diagnostics.errorCount, 1)
            XCTAssertFalse(snapshot.hasErrors) // Diagnostics separate from snapshot
            // Snapshot should be empty since binding failed
            XCTAssertEqual(snapshot.resolvedValues.count, 0)
        }
    }

    func testPipelineFailureOnMissingRequiredValue() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
            // No default value - required
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // Missing app.name
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to missing required value")
        case let .failure(diagnostics, _):
            XCTAssertTrue(diagnostics.hasErrors)
            // Should have error about missing value or decode failure
            XCTAssertGreaterThan(diagnostics.errorCount, 0)
        }
    }

    // MARK: - Finalization Failure Tests

    func testPipelineFailureOnFinalizationError() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "TestApp"
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { _ in
                // Finalize always throws
                throw TestError.missingPort
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to finalization error")
        case let .failure(diagnostics, snapshot):
            XCTAssertTrue(diagnostics.hasErrors)
            // Should have successfully resolved the binding before finalization failed
            XCTAssertEqual(snapshot.resolvedValues.count, 1)
        }
    }

    // MARK: - Final Spec Failure Tests

    func testPipelineFailureOnFinalSpecViolation() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "TestApp"
        )

        // Final spec that always fails
        let alwaysFailSpec = PredicateSpec<TestConfig> { _ in false }

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            finalSpecs: [AnySpecification(alwaysFailSpec)],
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to final spec violation")
        case let .failure(diagnostics, _):
            XCTAssertTrue(diagnostics.hasErrors)
            let errorMessages = diagnostics.diagnostics
                .filter { $0.severity == .error }
                .map(\.message)
            XCTAssertTrue(errorMessages.contains(where: { $0.contains("specification") }))
        }
    }

    // MARK: - Ordering and Determinism Tests

    func testBindingsAppliedInDeclaredOrder() {
        var applicationOrder: [String] = []

        let binding1 = Binding(
            key: "key1",
            keyPath: \TestDraft.name,
            decoder: { reader, key in
                applicationOrder.append("key1")
                return reader.string(forKey: ConfigKey(key))
            }
        )

        let binding2 = Binding(
            key: "key2",
            keyPath: \TestDraft.port,
            decoder: { reader, key in
                applicationOrder.append("key2")
                return reader.int(forKey: ConfigKey(key))
            }
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(binding1), AnyBinding(binding2)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: draft.port ?? 0, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "key1": "value1",
            "key2": 123,
        ])
        let reader = ConfigReader(provider: provider)

        _ = ConfigPipeline.build(profile: profile, reader: reader)

        // Verify bindings were applied in declaration order
        XCTAssertEqual(applicationOrder, ["key1", "key2"])
    }

    func testSnapshotContainsResolvedValues() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "DefaultApp"
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            XCTAssertEqual(snapshot.resolvedValues.count, 1)
            XCTAssertEqual(snapshot.resolvedValues[0].key, "app.name")
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - BuildResult Convenience Tests

    func testBuildResultDiagnosticsAccessor() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // Missing required value will cause failure
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        // Test diagnostics accessor works for both success and failure
        XCTAssertTrue(result.diagnostics.hasErrors)
    }

    func testBuildResultSnapshotAccessor() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "TestApp"
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        // Test snapshot accessor works
        XCTAssertNotNil(result.snapshot)
        XCTAssertFalse(result.snapshot.resolvedValues.isEmpty)
    }
}
