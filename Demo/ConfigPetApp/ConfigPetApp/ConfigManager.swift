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

    /// Tracks provenance metadata from the config reader.
    private var provenanceReporter: ResolvedValueProvenanceReporter?

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
            let reporter = ResolvedValueProvenanceReporter()
            let newReader = try loader.createReader(accessReporter: reporter)
            reader = newReader
            provenanceReporter = reporter
            build(with: newReader, provenanceReporter: reporter)
            loadError = nil
        } catch {
            reader = nil
            buildResult = nil
            config = nil
            loadError = error
            provenanceReporter = nil
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
        sleepOverride = false
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

    /// Describes the current evaluation context (day/night, reload count).
    var contextDescription: String {
        DemoContextProvider.shared.contextSummary
    }

    /// Indicates whether a manual night override is active.
    var isNightOverrideActive: Bool {
        DemoContextProvider.shared.isNightOverrideActive
    }

    /// The latest snapshot produced by the configuration pipeline.
    var snapshot: Snapshot? {
        buildResult?.snapshot
    }

    /// Resolved values captured in the latest snapshot.
    var resolvedValues: [ResolvedValue] {
        snapshot?.resolvedValues ?? []
    }

    /// Decision traces recorded in the latest snapshot.
    var decisionTraces: [DecisionTrace] {
        snapshot?.decisionTraces ?? []
    }

    /// Human-readable timestamp of the last snapshot.
    var snapshotTimestampDescription: String? {
        guard let timestamp = snapshot?.timestamp else { return nil }
        return Self.snapshotDateFormatter.string(from: timestamp)
    }

    func toggleNightMode() {
        DemoContextProvider.shared.toggleNightOverride()
        rebuildConfig()
    }

    private func rebuildConfig() {
        guard let existingReader = reader else { return }
        build(with: existingReader, provenanceReporter: provenanceReporter)
    }

    private func build(
        with reader: ConfigReader,
        provenanceReporter: ResolvedValueProvenanceReporter?
    ) {
        DemoContextProvider.shared.recordReload()
        let result = ConfigPipeline.build(
            profile: AppConfig.profile,
            reader: reader,
            provenanceReporter: provenanceReporter
        )
        buildResult = result
        if case let .success(config, _) = result {
            self.config = config
        } else {
            config = nil
        }
    }

    private static let snapshotDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
