import Configuration
@testable import SpecificationConfig
import XCTest

final class ConfigReaderEnvironmentOverridesTests: XCTestCase {
    func testEnvironmentOverridesFileValues() throws {
        let reader = ConfigReader.withEnvironmentOverrides(
            values: ["pet.name": "FilePet"],
            environmentVariables: ["PET_NAME": "EnvPet"]
        )

        XCTAssertEqual(reader.string(forKey: ConfigKey("pet.name")), "EnvPet")
    }

    func testEnvironmentOverridesSupportCamelCaseKeys() throws {
        let reader = ConfigReader.withEnvironmentOverrides(
            values: ["pet.isSleeping": false],
            environmentVariables: ["PET_IS_SLEEPING": "true"]
        )

        XCTAssertEqual(reader.bool(forKey: ConfigKey("pet.isSleeping")), true)
    }

    func testFallsBackToFileValuesWhenEnvMissing() throws {
        let reader = ConfigReader.withEnvironmentOverrides(
            values: ["pet.name": "FilePet"],
            environmentVariables: [:]
        )

        XCTAssertEqual(reader.string(forKey: ConfigKey("pet.name")), "FilePet")
    }
}
