import Configuration
import Foundation
import SpecificationConfig

/// Manages configuration loading for the application.
///
/// Holds the ConfigReader instance and provides reload capability.
@MainActor
class ConfigManager: ObservableObject {
    /// The configuration reader, if successfully loaded.
    @Published var reader: Configuration.ConfigReader?

    /// The last build result from the configuration pipeline.
    @Published var buildResult: BuildResult<AppConfig>?

    /// The finalized app configuration, when build succeeds.
    @Published var config: AppConfig?

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
            buildResult = reader.map { ConfigPipeline.build(profile: AppConfig.profile, reader: $0) }
            if case let .success(config, _) = buildResult {
                self.config = config
            } else {
                config = nil
            }
            loadError = nil
        } catch {
            reader = nil
            buildResult = nil
            config = nil
            loadError = error
        }
    }

    /// Provides a debug description of the configuration status.
    var statusDescription: String {
        if let error = loadError {
            "Error: \(error.localizedDescription)"
        } else if let buildResult {
            switch buildResult {
            case .success:
                "Config built successfully"
            case let .failure(diagnostics, _):
                "Config build failed (\(diagnostics.errorCount) errors)"
            }
        } else if reader != nil {
            "Config loaded successfully"
        } else {
            "No config loaded"
        }
    }
}
