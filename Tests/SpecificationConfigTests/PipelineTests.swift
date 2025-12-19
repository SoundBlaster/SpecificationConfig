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
            valueSpecs: [SpecEntry(positiveSpec)]
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

    func testDecisionBindingAppliesFallbackAndRecordsTrace() {
        struct DecisionDraft {
            var petName: String?
            var isSleeping: Bool?
        }

        struct DecisionConfig: Equatable {
            let petName: String
            let isSleeping: Bool
        }

        enum DecisionError: Error {
            case missingName
            case missingSleepFlag
        }

        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \DecisionDraft.isSleeping,
            decoder: ConfigReader.bool
        )

        let nameFallback = DecisionEntry(
            description: "Sleeping pet",
            predicate: { (draft: DecisionDraft) in draft.isSleeping == true },
            result: "Sleepy"
        )

        let decisionBinding = DecisionBinding(
            key: "pet.name",
            keyPath: \DecisionDraft.petName,
            decisions: [nameFallback]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(sleepingBinding)],
            decisionBindings: [AnyDecisionBinding(decisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw DecisionError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw DecisionError.missingSleepFlag
                }
                return DecisionConfig(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { DecisionDraft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.isSleeping": true,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config, DecisionConfig(petName: "Sleepy", isSleeping: true))
            XCTAssertEqual(snapshot.decisionTraces.count, 1)
            let trace = snapshot.decisionTrace(forKey: "pet.name")
            XCTAssertEqual(trace?.decisionName, "Sleeping pet")
            XCTAssertEqual(trace?.matchedIndex, 0)
            let resolved = snapshot.value(forKey: "pet.name")
            XCTAssertEqual(resolved?.stringifiedValue, "Sleepy")
            XCTAssertEqual(resolved?.provenance, .decisionFallback)
        case .failure:
            XCTFail("Expected decision fallback to succeed")
        }
    }

    func testDecisionBindingNoMatchAddsDiagnostic() {
        struct DecisionDraft {
            var petName: String?
            var isSleeping: Bool?
        }

        struct DecisionConfig {
            let petName: String
            let isSleeping: Bool
        }

        enum DecisionError: Error {
            case missingName
            case missingSleepFlag
        }

        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \DecisionDraft.isSleeping,
            decoder: ConfigReader.bool
        )

        let nameFallback = DecisionEntry(
            description: "Sleeping pet",
            predicate: { (draft: DecisionDraft) in draft.isSleeping == true },
            result: "Sleepy"
        )

        let decisionBinding = DecisionBinding(
            key: "pet.name",
            keyPath: \DecisionDraft.petName,
            decisions: [nameFallback]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(sleepingBinding)],
            decisionBindings: [AnyDecisionBinding(decisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw DecisionError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw DecisionError.missingSleepFlag
                }
                return DecisionConfig(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { DecisionDraft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.isSleeping": false,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected decision fallback failure")
        case let .failure(diagnostics, snapshot):
            XCTAssertTrue(diagnostics.hasErrors)
            XCTAssertEqual(snapshot.decisionTraces.count, 0)
            let error = diagnostics.diagnostics.first { $0.key == "pet.name" }
            XCTAssertTrue(error?.message.contains("Decision fallback") ?? false)
        }
    }

    func testDiagnosticsIncludeSpecMetadataForValueSpecFailure() {
        let positiveSpec = PredicateSpec<Int>(description: "Positive port") { $0 > 0 }

        let portBinding = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(portBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "app.port": -1,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to spec violation")
        case let .failure(diagnostics, _):
            let error = diagnostics.diagnostics.first { $0.key == "app.port" }
            XCTAssertEqual(error?.context["spec"]?.rawValue, "Positive port")
            XCTAssertTrue(error?.context["specType"]?.rawValue.contains("PredicateSpec") ?? false)
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
        let alwaysFailSpec = PredicateSpec<TestConfig>(description: "Always fail") { _ in false }

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            finalSpecs: [SpecEntry(alwaysFailSpec)],
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

    func testDiagnosticsIncludeSpecMetadataForFinalSpecFailure() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            defaultValue: "TestApp"
        )

        let alwaysFailSpec = PredicateSpec<TestConfig>(description: "Always fail") { _ in false }

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            finalSpecs: [SpecEntry(alwaysFailSpec)],
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to final spec violation")
        case let .failure(diagnostics, _):
            let error = diagnostics.diagnostics.first { $0.message.contains("Post-finalization") }
            XCTAssertEqual(error?.context["spec"]?.rawValue, "Always fail")
            XCTAssertTrue(error?.context["specType"]?.rawValue.contains("PredicateSpec") ?? false)
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

    // MARK: - Error Handling Mode Tests

    func testCollectAllModeWithMultipleErrors() {
        // Create bindings: 1st succeeds, 2nd fails, 3rd fails
        let binding1 = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let positiveSpec = PredicateSpec<Int> { $0 > 0 }
        let binding2 = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let nonEmptySpec = PredicateSpec<String> { !$0.isEmpty }
        let binding3 = Binding(
            key: "app.tag",
            keyPath: \TestDraft.name, // Reuse name field
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(nonEmptySpec)]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(binding1), AnyBinding(binding2), AnyBinding(binding3)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // Provide values: name is valid, port is negative (fails), tag is empty (fails)
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": -1,
            "app.tag": "",
        ])
        let reader = ConfigReader(provider: provider)

        // Use default mode (collect-all)
        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure due to multiple spec violations")
        case let .failure(diagnostics, snapshot):
            // Should have collected 2 errors (port and tag)
            XCTAssertTrue(diagnostics.hasErrors)
            XCTAssertEqual(diagnostics.errorCount, 2)
            // Snapshot should contain 1 resolved value (name succeeded)
            XCTAssertEqual(snapshot.resolvedValues.count, 1)
            XCTAssertEqual(snapshot.resolvedValues[0].key, "app.name")
        }
    }

    func testFailFastModeStopsAtFirstError() {
        var bindingsAttempted: [String] = []

        // Create bindings with side effects to track execution
        let binding1 = Binding(
            key: "key1",
            keyPath: \TestDraft.name,
            decoder: { reader, key in
                bindingsAttempted.append("key1")
                return reader.string(forKey: ConfigKey(key))
            }
        )

        let failingSpec = PredicateSpec<Int> { _ in false }
        let binding2 = Binding(
            key: "key2",
            keyPath: \TestDraft.port,
            decoder: { reader, key in
                bindingsAttempted.append("key2")
                return reader.int(forKey: ConfigKey(key))
            },
            valueSpecs: [SpecEntry(failingSpec)]
        )

        let binding3 = Binding(
            key: "key3",
            keyPath: \TestDraft.isEnabled,
            decoder: { reader, key in
                bindingsAttempted.append("key3")
                return reader.bool(forKey: ConfigKey(key))
            }
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(binding1), AnyBinding(binding2), AnyBinding(binding3)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "key1": "value1",
            "key2": 123,
            "key3": true,
        ])
        let reader = ConfigReader(provider: provider)

        // Use fail-fast mode
        let result = ConfigPipeline.build(
            profile: profile,
            reader: reader,
            errorHandlingMode: .failFast
        )

        switch result {
        case .success:
            XCTFail("Expected failure due to spec violation")
        case let .failure(diagnostics, snapshot):
            // Should have only 1 error (stopped at key2)
            XCTAssertEqual(diagnostics.errorCount, 1)
            // Verify key3 was not attempted
            XCTAssertEqual(bindingsAttempted, ["key1", "key2"])
            // Snapshot should contain 1 value (key1 succeeded)
            XCTAssertEqual(snapshot.resolvedValues.count, 1)
        }
    }

    func testDefaultModeIsCollectAll() {
        // Create bindings that will fail
        let positiveSpec = PredicateSpec<Int> { $0 > 0 }
        let binding1 = Binding(
            key: "port1",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let binding2 = Binding(
            key: "port2",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(binding1), AnyBinding(binding2)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // Both ports are negative (will fail)
        let provider = InMemoryProvider(values: [
            "port1": -1,
            "port2": -2,
        ])
        let reader = ConfigReader(provider: provider)

        // Call without specifying mode (should use default collect-all)
        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case let .failure(diagnostics, _):
            // Should have 2 errors (collect-all behavior)
            XCTAssertEqual(diagnostics.errorCount, 2)
        }
    }

    func testCollectAllModeWithAllBindingsFailing() {
        let positiveSpec = PredicateSpec<Int> { $0 > 0 }
        let binding1 = Binding(
            key: "port1",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let binding2 = Binding(
            key: "port2",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let binding3 = Binding(
            key: "port3",
            keyPath: \TestDraft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) },
            valueSpecs: [SpecEntry(positiveSpec)]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(binding1), AnyBinding(binding2), AnyBinding(binding3)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )

        // All ports are negative (all will fail)
        let provider = InMemoryProvider(values: [
            "port1": -1,
            "port2": -2,
            "port3": -3,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(
            profile: profile,
            reader: reader,
            errorHandlingMode: .collectAll
        )

        switch result {
        case .success:
            XCTFail("Expected failure")
        case let .failure(diagnostics, snapshot):
            // Should have 3 errors
            XCTAssertEqual(diagnostics.errorCount, 3)
            // Snapshot should be empty (no successful bindings)
            XCTAssertEqual(snapshot.resolvedValues.count, 0)
        }
    }

    // MARK: - Provenance Tracking Tests

    func testSnapshotContainsActualStringifiedValues() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string
        )

        let portBinding = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: ConfigReader.int
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding), AnyBinding(portBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: draft.port ?? 0, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            XCTAssertEqual(snapshot.resolvedValues.count, 2)

            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertEqual(nameValue?.stringifiedValue, "TestApp")
            XCTAssertEqual(nameValue?.provenance, .unknown)

            let portValue = snapshot.value(forKey: "app.port")
            XCTAssertEqual(portValue?.stringifiedValue, "8080")
            XCTAssertEqual(portValue?.provenance, .unknown)

        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSnapshotTracksIsSecretFlag() {
        let apiKeyBinding = Binding(
            key: "api.key",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string,
            isSecret: true
        )

        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string,
            isSecret: false
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(apiKeyBinding), AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        let provider = InMemoryProvider(values: [
            "api.key": "secret123",
            "app.name": "TestApp",
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            let apiKeyValue = snapshot.value(forKey: "api.key")
            XCTAssertEqual(apiKeyValue?.isSecret, true)
            XCTAssertEqual(apiKeyValue?.displayValue, "[REDACTED]")
            XCTAssertEqual(apiKeyValue?.stringifiedValue, "secret123")

            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertEqual(nameValue?.isSecret, false)
            XCTAssertEqual(nameValue?.displayValue, "TestApp")

        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSnapshotProvenanceDefaultValue() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string,
            defaultValue: "DefaultApp"
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "", port: 3000, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        // No value provided, default should be used
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertEqual(nameValue?.stringifiedValue, "DefaultApp")
            XCTAssertEqual(nameValue?.provenance, .defaultValue)

        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSnapshotHandlesNilValues() {
        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                TestConfig(name: draft.name ?? "<none>", port: 3000, isEnabled: false)
            },
            makeDraft: { TestDraft() }
        )

        // No value provided, no default
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertEqual(nameValue?.stringifiedValue, "<nil>")

        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSnapshotStringifiesDifferentTypes() {
        struct TestDraft2 {
            var name: String?
            var port: Int?
            var enabled: Bool?
        }

        let nameBinding = Binding(
            key: "app.name",
            keyPath: \TestDraft2.name,
            decoder: ConfigReader.string
        )

        let portBinding = Binding(
            key: "app.port",
            keyPath: \TestDraft2.port,
            decoder: ConfigReader.int
        )

        let enabledBinding = Binding(
            key: "app.enabled",
            keyPath: \TestDraft2.enabled,
            decoder: ConfigReader.bool
        )

        let profile = SpecProfile(
            bindings: [
                AnyBinding(nameBinding),
                AnyBinding(portBinding),
                AnyBinding(enabledBinding),
            ],
            finalize: { draft in
                TestConfig(
                    name: draft.name ?? "",
                    port: draft.port ?? 0,
                    isEnabled: draft.enabled ?? false
                )
            },
            makeDraft: { TestDraft2() }
        )

        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
            "app.enabled": true,
        ])
        let reader = ConfigReader(provider: provider)

        let result = ConfigPipeline.build(profile: profile, reader: reader)

        switch result {
        case let .success(_, snapshot):
            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertEqual(nameValue?.stringifiedValue, "TestApp")

            let portValue = snapshot.value(forKey: "app.port")
            XCTAssertEqual(portValue?.stringifiedValue, "8080")

            let enabledValue = snapshot.value(forKey: "app.enabled")
            XCTAssertEqual(enabledValue?.stringifiedValue, "true")

        case .failure:
            XCTFail("Expected success")
        }
    }
}
