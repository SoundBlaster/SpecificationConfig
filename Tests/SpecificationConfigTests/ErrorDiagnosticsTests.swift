@testable import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

/// Tests for improved error diagnostics distinguishing decode vs validation failures.
final class ErrorDiagnosticsTests: XCTestCase {
    // MARK: - Test Types

    struct TestDraft {
        var name: String?
        var count: Int?
        var url: URL?
    }

    struct TestConfig {
        let name: String
        let count: Int
        let url: URL
    }

    enum TestError: Error {
        case missingName
        case missingCount
        case missingURL
    }

    // MARK: - Tests

    func testDecodeFailureProducesSpecificError() throws {
        // Given: A config with a decoder that throws an error
        struct DecodeError: Error, LocalizedError {
            var errorDescription: String? {
                "Expected integer value but got string"
            }
        }

        let provider = InMemoryProvider(values: [
            AbsoluteConfigKey(stringLiteral: "name"): ConfigValue(stringLiteral: "TestName"),
            AbsoluteConfigKey(stringLiteral: "count"): ConfigValue(stringLiteral: "not-a-number"),
        ])
        let reader = ConfigReader(provider: provider)

        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [
                AnyBinding(
                    Binding(
                        key: "name",
                        keyPath: \TestDraft.name,
                        decoder: ConfigReader.string
                    )
                ),
                AnyBinding(
                    Binding(
                        key: "count",
                        keyPath: \TestDraft.count,
                        decoder: { reader, key in
                            // Custom decoder that throws on type mismatch
                            if let value = try ConfigReader.int(reader, key) {
                                return value
                            }
                            // If value exists but isn't an int, throw error
                            if let stringValue: String = try ConfigReader.string(reader, key) {
                                throw DecodeError()
                            }
                            return nil
                        }
                    )
                ),
            ],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingName }
                guard let count = draft.count else { throw TestError.missingCount }
                // URL not required for this test
                return TestConfig(name: name, count: count, url: URL(string: "https://example.com")!)
            },
            makeDraft: TestDraft.init
        )

        // When: Building the config
        let result: BuildResult<TestConfig> = ConfigPipeline.build(profile: profile, reader: reader)

        // Then: Build fails with decode error
        guard case let .failure(diagnostics, _) = result else {
            XCTFail("Expected failure due to decode error")
            return
        }

        XCTAssertTrue(diagnostics.hasErrors)
        XCTAssertEqual(diagnostics.errorCount, 1)

        // Verify the error is a decode error with specific context
        let errors = diagnostics.diagnostics.filter { $0.severity == .error }
        XCTAssertEqual(errors.count, 1)

        let decodeError = errors.first!
        XCTAssertEqual(decodeError.key, "count")
        XCTAssertTrue(decodeError.displayMessage.contains("decode"), "Error message should mention decode")
        XCTAssertTrue(decodeError.displayMessage.contains("count"), "Error message should mention the key")

        // Verify context contains error type information
        XCTAssertNotNil(decodeError.context["errorType"])
        XCTAssertEqual(decodeError.context["errorType"]?.displayValue, "Decode Error")
    }

    func testValidationFailureProducesSpecificError() throws {
        // Given: A config with valid values but failing validation spec
        let provider = InMemoryProvider(values: [
            AbsoluteConfigKey(stringLiteral: "name"): ConfigValue(stringLiteral: ""), // Empty string
            AbsoluteConfigKey(stringLiteral: "count"): ConfigValue(integerLiteral: 42),
        ])
        let reader = ConfigReader(provider: provider)

        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [
                AnyBinding(
                    Binding(
                        key: "name",
                        keyPath: \TestDraft.name,
                        decoder: ConfigReader.string,
                        valueSpecs: [
                            SpecEntry(
                                PredicateSpec(description: "Name must not be empty") { (name: String) in
                                    !name.isEmpty
                                }
                            ),
                        ]
                    )
                ),
                AnyBinding(
                    Binding(
                        key: "count",
                        keyPath: \TestDraft.count,
                        decoder: ConfigReader.int
                    )
                ),
            ],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingName }
                guard let count = draft.count else { throw TestError.missingCount }
                return TestConfig(name: name, count: count, url: URL(string: "https://example.com")!)
            },
            makeDraft: TestDraft.init
        )

        // When: Building the config
        let result: BuildResult<TestConfig> = ConfigPipeline.build(profile: profile, reader: reader)

        // Then: Build fails with validation error
        guard case let .failure(diagnostics, _) = result else {
            XCTFail("Expected failure due to validation error")
            return
        }

        XCTAssertTrue(diagnostics.hasErrors)
        XCTAssertEqual(diagnostics.errorCount, 1)

        // Verify the error is a validation spec failure
        let errors = diagnostics.diagnostics.filter { $0.severity == .error }
        XCTAssertEqual(errors.count, 1)

        let validationError = errors.first!
        XCTAssertEqual(validationError.key, "name")
        XCTAssertTrue(validationError.displayMessage.contains("specification"), "Error message should mention specification")
        XCTAssertFalse(validationError.displayMessage.contains("decode"), "Error message should NOT mention decode")

        // Verify context contains spec information
        XCTAssertNotNil(validationError.context["spec"])
        XCTAssertEqual(validationError.context["spec"]?.displayValue, "Name must not be empty")
    }

    func testBothDecodeAndValidationErrorsDistinguishable() throws {
        // Given: A config with both decode and validation failures
        struct DecodeError: Error, LocalizedError {
            var errorDescription: String? {
                "Expected integer value but got string"
            }
        }

        let provider = InMemoryProvider(values: [
            AbsoluteConfigKey(stringLiteral: "name"): ConfigValue(stringLiteral: ""), // Empty - will fail validation
            AbsoluteConfigKey(stringLiteral: "count"): ConfigValue(stringLiteral: "not-a-number"), // Will fail decode
        ])
        let reader = ConfigReader(provider: provider)

        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [
                AnyBinding(
                    Binding(
                        key: "name",
                        keyPath: \TestDraft.name,
                        decoder: ConfigReader.string,
                        valueSpecs: [
                            SpecEntry(
                                PredicateSpec(description: "Name must not be empty") { (name: String) in
                                    !name.isEmpty
                                }
                            ),
                        ]
                    )
                ),
                AnyBinding(
                    Binding(
                        key: "count",
                        keyPath: \TestDraft.count,
                        decoder: { reader, key in
                            // Custom decoder that throws on type mismatch
                            if let value = try ConfigReader.int(reader, key) {
                                return value
                            }
                            // If value exists but isn't an int, throw error
                            if let stringValue: String = try ConfigReader.string(reader, key) {
                                throw DecodeError()
                            }
                            return nil
                        }
                    )
                ),
            ],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingName }
                guard let count = draft.count else { throw TestError.missingCount }
                return TestConfig(name: name, count: count, url: URL(string: "https://example.com")!)
            },
            makeDraft: TestDraft.init
        )

        // When: Building the config
        let result: BuildResult<TestConfig> = ConfigPipeline.build(profile: profile, reader: reader)

        // Then: Build fails with both types of errors
        guard case let .failure(diagnostics, _) = result else {
            XCTFail("Expected failure")
            return
        }

        XCTAssertTrue(diagnostics.hasErrors)
        // We should have 2 errors: one validation error (name), one decode error (count)
        XCTAssertEqual(diagnostics.errorCount, 2, "Should have both validation and decode errors")

        let errors = diagnostics.diagnostics.filter { $0.severity == .error }

        // Find the validation error (for name)
        let validationError = errors.first { $0.key == "name" }
        XCTAssertNotNil(validationError, "Should have validation error for name")
        if let validationError {
            XCTAssertTrue(validationError.displayMessage.contains("specification"))
            XCTAssertNotNil(validationError.context["spec"])
        }

        // Find the decode error (for count)
        let decodeError = errors.first { $0.key == "count" }
        XCTAssertNotNil(decodeError, "Should have decode error for count")
        if let decodeError {
            XCTAssertTrue(decodeError.displayMessage.contains("decode"))
            XCTAssertNotNil(decodeError.context["errorType"])
        }
    }

    func testDecodeErrorContainsUnderlyingErrorDetails() throws {
        // Given: A config that will throw a custom decoder error
        struct CustomDecodeError: Error, LocalizedError {
            var errorDescription: String? {
                "Invalid URL format: expected https:// protocol"
            }
        }

        let provider = InMemoryProvider(values: [
            AbsoluteConfigKey(stringLiteral: "url"): ConfigValue(stringLiteral: "not-a-valid-url"),
        ])
        let reader = ConfigReader(provider: provider)

        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [
                AnyBinding(
                    Binding(
                        key: "url",
                        keyPath: \TestDraft.url,
                        decoder: { reader, key in
                            guard let urlString = try ConfigReader.string(reader, key) else { return nil }
                            guard let url = URL(string: urlString), url.scheme == "https" else {
                                throw CustomDecodeError()
                            }
                            return url
                        }
                    )
                ),
            ],
            finalize: { draft in
                guard let url = draft.url else { throw TestError.missingURL }
                return TestConfig(name: "Test", count: 1, url: url)
            },
            makeDraft: TestDraft.init
        )

        // When: Building the config
        let result: BuildResult<TestConfig> = ConfigPipeline.build(profile: profile, reader: reader)

        // Then: Build fails with decode error containing details
        guard case let .failure(diagnostics, _) = result else {
            XCTFail("Expected failure")
            return
        }

        XCTAssertTrue(diagnostics.hasErrors)

        let errors = diagnostics.diagnostics.filter { $0.severity == .error }
        XCTAssertEqual(errors.count, 1)

        let error = errors.first!
        XCTAssertEqual(error.key, "url")
        // Error message should include the underlying custom error message
        XCTAssertTrue(error.displayMessage.contains("https://"))
        XCTAssertNotNil(error.context["underlyingError"])
    }

    func testAsyncSpecErrorNotMisclassifiedAsDecodeFailure() async throws {
        // Given: An async spec that throws a non-ConfigError during evaluation
        struct NetworkError: Error, LocalizedError {
            var errorDescription: String? {
                "Network timeout during validation"
            }
        }

        struct ThrowingAsyncSpec: AsyncSpecification {
            func isSatisfiedBy(_: String) async throws -> Bool {
                // Simulate a network/validation error that's not a ConfigError
                throw NetworkError()
            }
        }

        let provider = InMemoryProvider(values: [
            AbsoluteConfigKey(stringLiteral: "name"): ConfigValue(stringLiteral: "ValidName"),
        ])
        let reader = ConfigReader(provider: provider)

        let profile = SpecProfile<TestDraft, TestConfig>(
            bindings: [
                AnyBinding(
                    Binding(
                        key: "name",
                        keyPath: \TestDraft.name,
                        decoder: ConfigReader.string,
                        asyncValueSpecs: [
                            AsyncSpecEntry(
                                ThrowingAsyncSpec(),
                                description: "Network validation"
                            ),
                        ]
                    )
                ),
            ],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingName }
                return TestConfig(name: name, count: 1, url: URL(string: "https://example.com")!)
            },
            makeDraft: TestDraft.init
        )

        // When: Building async config
        let result: BuildResult<TestConfig> = await ConfigPipeline.buildAsync(profile: profile, reader: reader)

        // Then: Error should be classified as asyncSpecFailed, NOT decodeFailed
        guard case let .failure(diagnostics, _) = result else {
            XCTFail("Expected failure")
            return
        }

        XCTAssertTrue(diagnostics.hasErrors)
        XCTAssertEqual(diagnostics.errorCount, 1)

        let errors = diagnostics.diagnostics.filter { $0.severity == .error }
        let error = errors.first!

        // Verify it's an async spec failure, not a decode failure
        XCTAssertTrue(
            error.displayMessage.contains("Async specification failed"),
            "Error should be async spec failure, not decode failure. Got: \(error.displayMessage)"
        )
        XCTAssertFalse(
            error.displayMessage.contains("decode"),
            "Error should NOT mention decode. Got: \(error.displayMessage)"
        )

        // Should have spec context, not decode error context
        XCTAssertNotNil(error.context["spec"])
        XCTAssertNil(error.context["errorType"], "Should not have decode error context")
    }
}
