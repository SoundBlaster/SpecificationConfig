import Configuration
import Foundation

/// Manages configuration loading for the application.
///
/// Holds the ConfigReader instance and provides reload capability.
@MainActor
class ConfigManager: ObservableObject {
    /// The configuration reader, if successfully loaded.
    @Published var reader: Configuration.ConfigReader?

    /// The error that occurred during loading, if any.
    @Published var loadError: Error?

    /// Initializes the manager and loads configuration.
    init() {
        loadConfig()
    }

    /// Loads or reloads the configuration.
    ///
    /// Attempts to find and load config.json using ConfigFileLoader.
    /// Updates `reader` and `loadError` based on the result.
    func loadConfig() {
        do {
            let loader = ConfigFileLoader.findConfigFile() ?? ConfigFileLoader()
            reader = try loader.createReader()
            loadError = nil
        } catch {
            reader = nil
            loadError = error
        }
    }

    /// Provides a debug description of the configuration status.
    var statusDescription: String {
        if let error = loadError {
            return "Error: \(error.localizedDescription)"
        } else if reader != nil {
            return "Config loaded successfully"
        } else {
            return "No config loaded"
        }
    }
}
