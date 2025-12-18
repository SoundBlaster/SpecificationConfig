@testable import Configuration
@testable import SpecificationConfig
import XCTest

final class ConfigReaderHelpersTests: XCTestCase {
    // MARK: - Helper Functions

    private func makeReader(values: [AbsoluteConfigKey: ConfigValue] = [:]) -> ConfigReader {
        let provider = InMemoryProvider(values: values)
        return ConfigReader(provider: provider)
    }

    // MARK: - String Helper Tests

    func testStringHelperReadsValue() throws {
        let reader = makeReader(values: ["app.name": "TestApp"])

        let result = try ConfigReader.string(reader, "app.name")

        XCTAssertEqual(result, "TestApp")
    }

    func testStringHelperReturnsNilForMissingKey() throws {
        let reader = makeReader(values: [:])

        let result = try ConfigReader.string(reader, "missing.key")

        XCTAssertNil(result)
    }

    func testStringHelperReadsEmptyString() throws {
        let reader = makeReader(values: ["app.tag": ""])

        let result = try ConfigReader.string(reader, "app.tag")

        XCTAssertEqual(result, "")
    }

    // MARK: - Bool Helper Tests

    func testBoolHelperReadsTrue() throws {
        let reader = makeReader(values: ["app.enabled": true])

        let result = try ConfigReader.bool(reader, "app.enabled")

        XCTAssertEqual(result, true)
    }

    func testBoolHelperReadsFalse() throws {
        let reader = makeReader(values: ["app.disabled": false])

        let result = try ConfigReader.bool(reader, "app.disabled")

        XCTAssertEqual(result, false)
    }

    func testBoolHelperReturnsNilForMissingKey() throws {
        let reader = makeReader(values: [:])

        let result = try ConfigReader.bool(reader, "missing.key")

        XCTAssertNil(result)
    }

    // MARK: - Int Helper Tests

    func testIntHelperReadsPositiveValue() throws {
        let reader = makeReader(values: ["app.port": 8080])

        let result = try ConfigReader.int(reader, "app.port")

        XCTAssertEqual(result, 8080)
    }

    func testIntHelperReadsNegativeValue() throws {
        let reader = makeReader(values: ["app.offset": -42])

        let result = try ConfigReader.int(reader, "app.offset")

        XCTAssertEqual(result, -42)
    }

    func testIntHelperReadsZero() throws {
        let reader = makeReader(values: ["app.count": 0])

        let result = try ConfigReader.int(reader, "app.count")

        XCTAssertEqual(result, 0)
    }

    func testIntHelperReturnsNilForMissingKey() throws {
        let reader = makeReader(values: [:])

        let result = try ConfigReader.int(reader, "missing.key")

        XCTAssertNil(result)
    }

    // MARK: - Integration with Binding Tests

    func testStringHelperUsedAsDecoderInBinding() throws {
        struct TestDraft {
            var name: String?
        }

        let binding = Binding(
            key: "app.name",
            keyPath: \TestDraft.name,
            decoder: ConfigReader.string
        )
        let anyBinding = AnyBinding(binding)

        let reader = makeReader(values: ["app.name": "TestApp"])
        var draft = TestDraft()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.name, "TestApp")
    }

    func testIntHelperUsedAsDecoderInBinding() throws {
        struct TestDraft {
            var port: Int?
        }

        let binding = Binding(
            key: "app.port",
            keyPath: \TestDraft.port,
            decoder: ConfigReader.int
        )
        let anyBinding = AnyBinding(binding)

        let reader = makeReader(values: ["app.port": 8080])
        var draft = TestDraft()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.port, 8080)
    }

    func testBoolHelperUsedAsDecoderInBinding() throws {
        struct TestDraft {
            var enabled: Bool?
        }

        let binding = Binding(
            key: "app.enabled",
            keyPath: \TestDraft.enabled,
            decoder: ConfigReader.bool
        )
        let anyBinding = AnyBinding(binding)

        let reader = makeReader(values: ["app.enabled": true])
        var draft = TestDraft()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.enabled, true)
    }

    // MARK: - Multiple Helpers Test

    func testAllHelpersReturnNilForMissingKeys() throws {
        let reader = makeReader(values: [:])

        let stringResult = try ConfigReader.string(reader, "missing.string")
        let boolResult = try ConfigReader.bool(reader, "missing.bool")
        let intResult = try ConfigReader.int(reader, "missing.int")

        XCTAssertNil(stringResult)
        XCTAssertNil(boolResult)
        XCTAssertNil(intResult)
    }
}
