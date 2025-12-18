import Configuration
import Foundation
import SpecificationConfig

/// Loads configuration from config.json file.
///
/// Provides utilities to locate and load configuration files using
/// Swift Configuration's FileProvider.
struct ConfigFileLoader {
    /// Errors that can occur during config loading.
    enum LoadError: Error, LocalizedError {
        case fileNotFound(path: String)
        case invalidJSON(underlying: Error)
        case readerCreationFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case let .fileNotFound(path):
                "Configuration file not found at: \(path)"
            case let .invalidJSON(error):
                "Invalid JSON in config file: \(error.localizedDescription)"
            case let .readerCreationFailed(error):
                "Failed to create config reader: \(error.localizedDescription)"
            }
        }
    }

    /// The path to the configuration file.
    let configFilePath: String

    /// Creates a loader with the default config file path.
    ///
    /// The default path is `config.json` in the current working directory.
    init() {
        configFilePath = PathUtils.joinedPath(
            FileManager.default.currentDirectoryPath,
            "config.json"
        )
    }

    /// Creates a loader with a specific config file path.
    ///
    /// - Parameter configFilePath: Absolute path to the configuration file.
    init(configFilePath: String) {
        self.configFilePath = configFilePath
    }

    /// Creates a ConfigReader from the config file.
    ///
    /// - Returns: A ConfigReader instance ready to read configuration values.
    /// - Throws: LoadError if the file cannot be found or read.
    func createReader() throws -> Configuration.ConfigReader {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: configFilePath) else {
            throw LoadError.fileNotFound(path: configFilePath)
        }

        // Read and parse JSON file
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            // Flatten JSON into dot-notation keys for Configuration
            let flattenedConfig = flattenJSON(json)

            // Convert to Configuration types
            let configValues = flattenedConfig.reduce(into: [AbsoluteConfigKey: ConfigValue]()) { result, pair in
                let key = AbsoluteConfigKey(stringLiteral: pair.key)
                let value = convertToConfigValue(pair.value)
                result[key] = value
            }

            // Create InMemoryProvider with converted values
            let provider = InMemoryProvider(values: configValues)
            return ConfigReader(provider: provider)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain {
            throw LoadError.invalidJSON(underlying: error)
        } catch {
            throw LoadError.readerCreationFailed(underlying: error)
        }
    }

    /// Flattens nested JSON into dot-notation keys.
    ///
    /// Example: `{"pet": {"name": "Egorchi"}}` becomes `{"pet.name": "Egorchi"}`.
    private func flattenJSON(_ json: [String: Any], prefix: String = "") -> [String: Any] {
        var result: [String: Any] = [:]

        for (key, value) in json {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let nestedDict = value as? [String: Any] {
                // Recursively flatten nested dictionaries
                let flattened = flattenJSON(nestedDict, prefix: fullKey)
                result.merge(flattened) { _, new in new }
            } else {
                // Store primitive values
                result[fullKey] = value
            }
        }

        return result
    }

    /// Converts a JSON value to ConfigValue.
    private func convertToConfigValue(_ value: Any) -> ConfigValue {
        switch value {
        case let string as String:
            return ConfigValue(stringLiteral: string)
        case let number as NSNumber:
            // Check if it's a boolean
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return ConfigValue(booleanLiteral: number.boolValue)
            }
            // Try as Int first, then Double
            if Double(number.intValue) == number.doubleValue {
                return ConfigValue(integerLiteral: number.intValue)
            } else {
                return ConfigValue(floatLiteral: number.doubleValue)
            }
        case let bool as Bool:
            return ConfigValue(booleanLiteral: bool)
        case let int as Int:
            return ConfigValue(integerLiteral: int)
        case let double as Double:
            return ConfigValue(floatLiteral: double)
        default:
            // Fallback: convert to string
            return ConfigValue(stringLiteral: String(describing: value))
        }
    }

    /// Attempts to find config.json in common locations.
    ///
    /// Search order:
    /// 1. Current working directory
    /// 2. App bundle resources (if running as app)
    ///
    /// - Returns: ConfigFileLoader with resolved path, or nil if not found.
    static func findConfigFile() -> ConfigFileLoader? {
        let fileManager = FileManager.default

        // Try current directory
        let currentDirPath = PathUtils.joinedPath(
            fileManager.currentDirectoryPath,
            "config.json"
        )
        if fileManager.fileExists(atPath: currentDirPath) {
            return ConfigFileLoader(configFilePath: currentDirPath)
        }

        // Try app bundle
        if let bundlePath = Bundle.main.path(forResource: "config", ofType: "json") {
            return ConfigFileLoader(configFilePath: bundlePath)
        }

        return nil
    }
}
