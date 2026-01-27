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

    private func makeTemporaryDirectory() throws -> URL {
        let baseURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dirURL = baseURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }
}
