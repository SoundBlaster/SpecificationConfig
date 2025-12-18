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

    /// Temporary sleep override applied to the resolved config.
    @Published private var sleepOverride: Bool?

    private var sleepOverrideTask: Task<Void, Never>?

    /// Initializes the manager and loads configuration.
    init() {
        loadConfig()
    }

    /// Loads or reloads the configuration.
    ///
    /// Attempts to find and load config.json using ConfigFileLoader.
    /// Updates `reader` and `loadError` based on the result.
    func loadConfig() {
        sleepOverrideTask?.cancel()
        sleepOverride = nil
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

    /// The configuration with any active override applied.
    var effectiveConfig: AppConfig? {
        guard let config else { return nil }
        guard let sleepOverride else { return config }
        return AppConfig(petName: config.petName, isSleeping: sleepOverride)
    }

    /// Indicates whether a temporary sleep override is active.
    var isSleepOverrideActive: Bool {
        sleepOverride != nil
    }

    /// Forces the pet to sleep for a short duration.
    func triggerSleepOverride(duration: TimeInterval = 10) {
        guard config != nil else { return }
        sleepOverrideTask?.cancel()
        sleepOverride = true
        sleepOverrideTask = Task { [duration] in
            let nanoseconds = UInt64(duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            await MainActor.run {
                self.sleepOverride = nil
            }
        }
    }

    /// Provides a user-facing description of load/build status.
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
