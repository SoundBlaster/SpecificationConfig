@testable import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

final class ConfigLoaderTests: XCTestCase {
    // MARK: - Test Types

    struct TestDraft {
        var name: String?
        var port: Int?
    }

    struct TestConfig {
        let name: String
        let port: Int

        init(draft: TestDraft) throws {
            guard let name = draft.name else {
                throw TestError.missingName
            }
            self.name = name
            port = draft.port ?? 8080
        }
    }

    enum TestError: Error {
        case missingName
    }

    // MARK: - Helper Functions

    private func makeTestProfile() -> SpecProfile<TestDraft, TestConfig> {
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

        return SpecProfile(
            bindings: [AnyBinding(nameBinding), AnyBinding(portBinding)],
            finalize: { try TestConfig(draft: $0) },
            makeDraft: { TestDraft() }
        )
    }

    // MARK: - Basic Functionality Tests

    func testConfigLoaderBuild() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result = loader.build()

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config.name, "TestApp")
            XCTAssertEqual(config.port, 8080)
            XCTAssertFalse(snapshot.hasErrors)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testConfigLoaderReload() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result = loader.reload()

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config.name, "TestApp")
            XCTAssertEqual(config.port, 8080) // Default value
            XCTAssertFalse(snapshot.hasErrors)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testConfigLoaderMultipleReloads() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        // First reload
        let result1 = loader.reload()
        switch result1 {
        case let .success(config, _):
            XCTAssertEqual(config.name, "TestApp")
        case .failure:
            XCTFail("First reload failed unexpectedly")
        }

        // Second reload
        let result2 = loader.reload()
        switch result2 {
        case let .success(config, _):
            XCTAssertEqual(config.name, "TestApp")
        case .failure:
            XCTFail("Second reload failed unexpectedly")
        }

        // Third reload
        let result3 = loader.reload()
        switch result3 {
        case let .success(config, _):
            XCTAssertEqual(config.name, "TestApp")
        case .failure:
            XCTFail("Third reload failed unexpectedly")
        }
    }

    func testConfigLoaderBuildAndReloadEquivalent() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 9000,
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let buildResult = loader.build()
        let reloadResult = loader.reload()

        // Both should succeed with same values
        switch (buildResult, reloadResult) {
        case let (.success(config1, _), .success(config2, _)):
            XCTAssertEqual(config1.name, config2.name)
            XCTAssertEqual(config1.port, config2.port)
        default:
            XCTFail("Expected both build and reload to succeed")
        }
    }

    // MARK: - Error Handling Tests

    func testConfigLoaderWithFailure() {
        let profile = makeTestProfile()
        // Missing required "app.name" key
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result = loader.build()

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(diagnostics, _):
            XCTAssertTrue(diagnostics.hasErrors)
            XCTAssertGreaterThan(diagnostics.errorCount, 0)
        }
    }

    func testConfigLoaderErrorHandlingModeCollectAll() {
        let profile = makeTestProfile()
        // Missing both required keys to test collectAll behavior
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(
            profile: profile,
            reader: reader,
            errorHandlingMode: .collectAll
        )

        let result = loader.build()

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(diagnostics, _):
            // With collectAll, we should see finalization error
            // (since bindings don't fail for missing keys with defaults)
            XCTAssertTrue(diagnostics.hasErrors)
        }
    }

    func testConfigLoaderErrorHandlingModeFailFast() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [:])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(
            profile: profile,
            reader: reader,
            errorHandlingMode: .failFast
        )

        let result = loader.build()

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(diagnostics, _):
            // Should fail during finalization due to missing name
            XCTAssertTrue(diagnostics.hasErrors)
        }
    }

    func testConfigLoaderValueSpecFailure() {
        let nameBinding = Binding<TestDraft, String>(
            key: "pet.name",
            keyPath: \TestDraft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            valueSpecs: [AnySpecification<String> { !$0.isEmpty }]
        )
        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                try TestConfig(draft: draft)
            },
            makeDraft: { TestDraft() }
        )
        let provider = InMemoryProvider(values: ["pet.name": ""])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result = loader.build()

        switch result {
        case .success:
            XCTFail("Expected value spec failure but got success")
        case let .failure(diagnostics, _):
            XCTAssertTrue(diagnostics.hasErrors)
        }
    }

    // MARK: - Snapshot Tests

    func testConfigLoaderSnapshot() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
            "app.port": 8080,
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result = loader.build()

        switch result {
        case let .success(_, snapshot):
            XCTAssertEqual(snapshot.resolvedValues.count, 2)
            XCTAssertFalse(snapshot.hasErrors)

            // Verify resolved values
            let nameValue = snapshot.value(forKey: "app.name")
            XCTAssertNotNil(nameValue)
            XCTAssertEqual(nameValue?.stringifiedValue, "TestApp")

            let portValue = snapshot.value(forKey: "app.port")
            XCTAssertNotNil(portValue)
            XCTAssertEqual(portValue?.stringifiedValue, "8080")

        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testConfigLoaderMultipleReloadsProduceIndependentSnapshots() {
        let profile = makeTestProfile()
        let provider = InMemoryProvider(values: [
            "app.name": "TestApp",
        ])
        let reader = ConfigReader(provider: provider)
        let loader = ConfigLoader(profile: profile, reader: reader)

        let result1 = loader.reload()
        let result2 = loader.reload()

        // Both should have their own independent snapshots
        switch (result1, result2) {
        case let (.success(_, snapshot1), .success(_, snapshot2)):
            // Snapshots should have same content but be independent instances
            XCTAssertEqual(snapshot1.resolvedValues.count, snapshot2.resolvedValues.count)
            XCTAssertEqual(
                snapshot1.value(forKey: "app.name")?.stringifiedValue,
                snapshot2.value(forKey: "app.name")?.stringifiedValue
            )
        default:
            XCTFail("Expected both reloads to succeed")
        }
    }
}
