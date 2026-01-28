@testable import ConfigPetApp
import XCTest

final class ConfigPetAppTests: XCTestCase {
    func testAppConfigProfileHasBindings() {
        XCTAssertEqual(AppConfig.profile.bindings.count, 2)
    }

    func testConfigFileLoaderInvalidJSONIsClassified() throws {
        let tempDir = try makeTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent("invalid.json")
        try "{".data(using: .utf8)!.write(to: fileURL)

        let loader = ConfigFileLoader(configFilePath: fileURL.path)

        do {
            _ = try loader.createReader()
            XCTFail("Expected invalid JSON error")
        } catch let error as ConfigFileLoader.LoadError {
            switch error {
            case .invalidJSON:
                break
            default:
                XCTFail("Expected invalidJSON, got \(error)")
            }
        }
    }

    func testConfigFileLoaderReadFailureIsNotInvalidJSON() throws {
        let tempDir = try makeTemporaryDirectory()
        let loader = ConfigFileLoader(configFilePath: tempDir.path)

        do {
            _ = try loader.createReader()
            XCTFail("Expected reader creation failure")
        } catch let error as ConfigFileLoader.LoadError {
            switch error {
            case .readerCreationFailed:
                break
            case .invalidJSON:
                XCTFail("Expected readerCreationFailed, got invalidJSON")
            default:
                XCTFail("Expected readerCreationFailed, got \(error)")
            }
        }
    }

    // MARK: - DemoDerivedState Tests

    func testDemoDerivedStateUsingSelfReferences() {
        // Test that DemoDerivedState works correctly with Self references in @Decides
        // This verifies the fix for the keyPath resolution error
        let derivedState = DemoDerivedState()
        
        // Test wrapped value access (no sleep override, daytime)
        DemoContextProvider.shared.setNightOverride(false)
        DemoContextProvider.shared.setSleepOverride(nil)
        let labelDaytime = derivedState.sleepLabelDerived
        XCTAssertEqual(labelDaytime, "Awake", "Should return 'Awake' during daytime with no override")
        
        // Test projected value access (this is where keyPath errors would occur)
        let matchDaytime = derivedState.sleepLabelMatch
        XCTAssertNil(matchDaytime, "Should be nil when using fallback value")
        
        // Test night time scenario
        DemoContextProvider.shared.setNightOverride(true)
        let labelNighttime = derivedState.sleepLabelDerived
        XCTAssertEqual(labelNighttime, "Sleepy", "Should return 'Sleepy' during nighttime")
        
        let matchNighttime = derivedState.sleepLabelMatch
        XCTAssertEqual(matchNighttime, "Sleepy", "Should match the spec during nighttime")
        
        // Test forced sleep override
        DemoContextProvider.shared.setSleepOverride(true)
        let labelForcedSleep = derivedState.sleepLabelDerived
        XCTAssertEqual(labelForcedSleep, "Forced Sleep", "Should return 'Forced Sleep' when sleep override is active and sleeping")
        
        let matchForcedSleep = derivedState.sleepLabelMatch
        XCTAssertEqual(matchForcedSleep, "Forced Sleep", "Should match forced sleep spec")
        
        // Test forced awake override
        DemoContextProvider.shared.setSleepOverride(false)
        let labelForcedAwake = derivedState.sleepLabelDerived
        XCTAssertEqual(labelForcedAwake, "Forced Awake", "Should return 'Forced Awake' when sleep override is active but not sleeping")
        
        let matchForcedAwake = derivedState.sleepLabelMatch
        XCTAssertEqual(matchForcedAwake, "Forced Awake", "Should match forced awake spec")
        
        // Clean up
        DemoContextProvider.shared.setNightOverride(nil)
        DemoContextProvider.shared.setSleepOverride(nil)
    }
    
    func testDemoDerivedStateProjectedValueAccess() {
        // Specifically test that projected value ($sleepLabel) can be accessed
        // This is the critical test for the keyPath resolution fix
        let derivedState = DemoDerivedState()
        
        // Reset to clean state (daytime, no overrides)
        DemoContextProvider.shared.setNightOverride(false)
        DemoContextProvider.shared.setSleepOverride(nil)
        
        // Access projected value multiple times (simulating reload scenario)
        for _ in 0..<5 {
            let match = derivedState.sleepLabelMatch
            // During daytime with no overrides, should use fallback (nil)
            // The fact that this doesn't crash proves the keyPath resolution works
            XCTAssertNil(match, "Should be nil when using fallback value")
        }
        
        // Now with a spec that matches
        DemoContextProvider.shared.setNightOverride(true)
        for _ in 0..<5 {
            let match = derivedState.sleepLabelMatch
            XCTAssertNotNil(match, "Should have a match value when spec is satisfied")
        }
        
        // Clean up
        DemoContextProvider.shared.setNightOverride(nil)
    }
    
    func testDemoDerivedStateIsNightTimeDerived() {
        let derivedState = DemoDerivedState()
        
        // Test daytime
        DemoContextProvider.shared.setNightOverride(false)
        XCTAssertFalse(derivedState.isNightTimeDerived, "Should be false during daytime")
        
        // Test nighttime
        DemoContextProvider.shared.setNightOverride(true)
        XCTAssertTrue(derivedState.isNightTimeDerived, "Should be true during nighttime")
        
        // Clean up
        DemoContextProvider.shared.setNightOverride(nil)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dirURL = baseURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }
}
