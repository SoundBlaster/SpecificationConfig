import Configuration
@testable import SpecificationConfig
import XCTest

final class ConfigSchemaTests: XCTestCase {
    func testAllRequiredKeysPresent() {
        let schema = ConfigSchema(requirements: [
            .required("app.name", check: .string),
            .required("app.port", check: .int),
        ])

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "app.name": "Test",
            "app.port": 8080,
        ]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertFalse(diagnostics.hasErrors)
        XCTAssertEqual(diagnostics.diagnostics.count, 0)
    }

    func testMissingRequiredKeyProducesError() {
        let schema = ConfigSchema(requirements: [
            .required("app.name"),
            .required("app.missing"),
        ])

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "app.name": "Test",
        ]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertTrue(diagnostics.hasErrors)
        XCTAssertEqual(diagnostics.diagnostics.count, 1)
        XCTAssertEqual(diagnostics.diagnostics[0].key, "app.missing")
        XCTAssertTrue(diagnostics.diagnostics[0].message.contains("Required key"))
    }

    func testOptionalKeyMissingDoesNotProduceError() {
        let schema = ConfigSchema(requirements: [
            .required("app.name"),
            .optional("app.color"),
        ])

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "app.name": "Test",
        ]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertFalse(diagnostics.hasErrors)
    }

    func testMultipleMissingRequiredKeys() {
        let schema = ConfigSchema(requirements: [
            .required("a"),
            .required("b"),
            .required("c"),
        ])

        let reader = ConfigReader(provider: InMemoryProvider(values: [:]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertEqual(diagnostics.errorCount, 3)

        let keys = diagnostics.diagnostics.map(\.key)
        XCTAssertTrue(keys.contains("a"))
        XCTAssertTrue(keys.contains("b"))
        XCTAssertTrue(keys.contains("c"))
    }

    func testEmptySchemaAlwaysValid() {
        let schema = ConfigSchema(requirements: [])
        let reader = ConfigReader(provider: InMemoryProvider(values: [:]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertFalse(diagnostics.hasErrors)
    }

    func testBoolCheckType() {
        let schema = ConfigSchema(requirements: [
            .required("flag", check: .bool),
        ])

        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "flag": true,
        ]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertFalse(diagnostics.hasErrors)
    }

    func testWrongCheckTypeProducesError() {
        let schema = ConfigSchema(requirements: [
            .required("port", check: .int),
        ])

        // "hello" is a string, not an int
        let reader = ConfigReader(provider: InMemoryProvider(values: [
            "port": "hello",
        ]))

        let diagnostics = schema.validate(reader: reader)
        XCTAssertTrue(diagnostics.hasErrors)
    }
}
