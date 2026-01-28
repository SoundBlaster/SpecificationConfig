import Foundation

/// Tracks the source of a resolved configuration value.
///
/// Provenance enables debugging by showing where each value originated:
/// file providers, environment variables, defaults, or unknown sources.
///
/// ## Example
///
/// ```swift
/// let provenance = Provenance.fileProvider(name: "config.json")
/// // Use in ResolvedValue to track where value came from
/// ```
public enum Provenance: Sendable, Equatable {
    /// Value came from a file provider (JSON, YAML, etc.)
    ///
    /// The associated name helps identify which file when multiple providers exist.
    case fileProvider(name: String)

    /// Value came from an environment variable
    case environmentVariable

    /// Value came from the binding's default value
    case defaultValue

    /// Value was derived from a decision fallback
    case decisionFallback

    /// Source could not be determined
    ///
    /// Use this when provenance tracking is unavailable or uncertain.
    case unknown
}

/// A single resolved configuration value with its provenance.
///
/// `ResolvedValue` captures not just the value itself, but also metadata about
/// where it came from and whether it should be redacted in logs/diagnostics.
///
/// ## Example
///
/// ```swift
/// let apiKey = ResolvedValue(
///     key: "api.key",
///     stringifiedValue: "secret123",
///     provenance: .environmentVariable,
///     isSecret: true
/// )
///
/// print(apiKey.displayValue) // "[REDACTED]"
/// print(apiKey.provenance)   // environmentVariable
/// ```
public struct ResolvedValue: Sendable, Equatable {
    /// The configuration key
    public let key: String

    /// The stringified value (before redaction)
    ///
    /// This is the actual value as a string. Use `displayValue` for
    /// user-facing output which applies redaction.
    public let stringifiedValue: String

    /// Where this value came from
    public let provenance: Provenance

    /// Whether this value is a secret and should be redacted in displays
    public let isSecret: Bool

    /// The display value with redaction applied.
    ///
    /// Returns `[REDACTED]` for secret values, or the actual value otherwise.
    /// Use this for logs, UI display, and diagnostics output.
    public var displayValue: String {
        Redaction.redact(stringifiedValue, isSecret: isSecret)
    }

    /// Creates a resolved value.
    ///
    /// - Parameters:
    ///   - key: The configuration key
    ///   - stringifiedValue: The value as a string
    ///   - provenance: Where the value came from
    ///   - isSecret: Whether to redact this value in displays (default: false)
    public init(
        key: String,
        stringifiedValue: String,
        provenance: Provenance,
        isSecret: Bool = false
    ) {
        self.key = key
        self.stringifiedValue = stringifiedValue
        self.provenance = provenance
        self.isSecret = isSecret
    }
}

/// A snapshot of the resolved configuration state.
///
/// Captures resolved values, decision traces, and diagnostics generated during
/// the build process. Snapshots provide visibility into where configuration
/// came from, how fallbacks were chosen, and what issues occurred.
///
/// ## Example
///
/// ```swift
/// let snapshot = Snapshot(
///     resolvedValues: [
///         ResolvedValue(
///             key: "app.name",
///             stringifiedValue: "MyApp",
///             provenance: .fileProvider(name: "config.json")
///         )
///     ],
///     diagnostics: DiagnosticsReport()
/// )
///
/// if let name = snapshot.value(forKey: "app.name") {
///     print(name.displayValue) // "MyApp"
/// }
/// ```
public struct Snapshot: Sendable {
    /// All resolved configuration values with their provenance
    public let resolvedValues: [ResolvedValue]

    /// Decision traces recorded during configuration resolution.
    public let decisionTraces: [DecisionTrace]

    /// When this snapshot was created
    public let timestamp: Date

    /// Diagnostic messages collected during configuration resolution.
    ///
    /// Contains errors, warnings, and informational messages with context
    /// about what went wrong and where.
    public let diagnostics: DiagnosticsReport

    /// Timing data captured during the pipeline build, if available.
    public let performanceMetrics: PerformanceMetrics?

    /// Pre-computed index for O(1) key lookups.
    private let resolvedValuesByKey: [String: ResolvedValue]

    /// Whether this snapshot contains any errors.
    ///
    /// Returns true if any diagnostic has severity `.error`.
    public var hasErrors: Bool {
        diagnostics.hasErrors
    }

    /// Creates a configuration snapshot.
    ///
    /// - Parameters:
    ///   - resolvedValues: The resolved configuration values (default: empty)
    ///   - decisionTraces: Decision traces recorded during resolution (default: empty)
    ///   - timestamp: When the snapshot was created (default: now)
    ///   - diagnostics: Collected diagnostics (default: empty report)
    ///   - performanceMetrics: Timing data from the pipeline build (default: nil)
    public init(
        resolvedValues: [ResolvedValue] = [],
        decisionTraces: [DecisionTrace] = [],
        timestamp: Date = Date(),
        diagnostics: DiagnosticsReport = DiagnosticsReport(),
        performanceMetrics: PerformanceMetrics? = nil
    ) {
        self.resolvedValues = resolvedValues
        resolvedValuesByKey = Dictionary(
            resolvedValues.map { ($0.key, $0) },
            uniquingKeysWith: { _, last in last }
        )
        self.decisionTraces = decisionTraces
        self.timestamp = timestamp
        self.diagnostics = diagnostics
        self.performanceMetrics = performanceMetrics
    }

    /// Finds a resolved value by key in O(1) time.
    ///
    /// - Parameter key: The configuration key to lookup
    /// - Returns: The resolved value if found, nil otherwise
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let timeout = snapshot.value(forKey: "http.timeout") {
    ///     print("Timeout: \(timeout.displayValue)")
    ///     print("Source: \(timeout.provenance)")
    /// }
    /// ```
    public func value(forKey key: String) -> ResolvedValue? {
        resolvedValuesByKey[key]
    }

    /// Finds a decision trace by key.
    ///
    /// - Parameter key: The configuration key to lookup.
    /// - Returns: The decision trace if found, nil otherwise.
    public func decisionTrace(forKey key: String) -> DecisionTrace? {
        decisionTraces.first { $0.key == key }
    }

    /// Computes the difference between this snapshot and a previous one.
    ///
    /// - Parameter previous: The earlier snapshot to compare against.
    /// - Returns: A `ConfigDiff` describing added, removed, and modified keys.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let diff = currentSnapshot.diff(from: previousSnapshot)
    /// if !diff.isEmpty {
    ///     print("Added: \(diff.added.map(\.key))")
    ///     print("Removed: \(diff.removed.map(\.key))")
    ///     print("Modified: \(diff.modified.map(\.key))")
    /// }
    /// ```
    public func diff(from previous: Snapshot) -> ConfigDiff {
        let currentByKey = resolvedValuesByKey
        let previousByKey = previous.resolvedValuesByKey

        let currentKeys = Set(currentByKey.keys)
        let previousKeys = Set(previousByKey.keys)

        let added = currentKeys.subtracting(previousKeys)
            .sorted()
            .compactMap { currentByKey[$0] }

        let removed = previousKeys.subtracting(currentKeys)
            .sorted()
            .compactMap { previousByKey[$0] }

        var modified: [ConfigDiff.ModifiedValue] = []
        for key in currentKeys.intersection(previousKeys).sorted() {
            guard let current = currentByKey[key], let prev = previousByKey[key] else { continue }
            if current.stringifiedValue != prev.stringifiedValue || current.provenance != prev.provenance {
                modified.append(ConfigDiff.ModifiedValue(
                    key: key,
                    oldValue: prev.stringifiedValue,
                    newValue: current.stringifiedValue,
                    oldProvenance: prev.provenance,
                    newProvenance: current.provenance
                ))
            }
        }

        return ConfigDiff(added: added, removed: removed, modified: modified)
    }
}

/// Timing data captured during a pipeline build.
///
/// Records per-binding, per-decision-binding, finalization, and total durations
/// to help identify slow decoders or specifications.
///
/// ## Example
///
/// ```swift
/// if let metrics = snapshot.performanceMetrics {
///     print("Total: \(metrics.totalDuration)")
///     for (key, duration) in metrics.bindingDurations {
///         print("\(key): \(duration)")
///     }
/// }
/// ```
public struct PerformanceMetrics: Sendable {
    /// Time spent applying each binding, keyed by binding key.
    public let bindingDurations: [String: Duration]

    /// Time spent evaluating each decision binding, keyed by decision binding key.
    public let decisionBindingDurations: [String: Duration]

    /// Time spent finalizing the draft and running final specs.
    public let finalizationDuration: Duration

    /// Total pipeline build duration.
    public let totalDuration: Duration
}

/// Describes the difference between two configuration snapshots.
public struct ConfigDiff: Sendable, Equatable {
    /// A value that was modified between snapshots.
    public struct ModifiedValue: Sendable, Equatable {
        /// The configuration key
        public let key: String
        /// The previous stringified value
        public let oldValue: String
        /// The current stringified value
        public let newValue: String
        /// The previous provenance
        public let oldProvenance: Provenance
        /// The current provenance
        public let newProvenance: Provenance
    }

    /// Keys that exist in the current snapshot but not the previous one.
    public let added: [ResolvedValue]

    /// Keys that existed in the previous snapshot but not the current one.
    public let removed: [ResolvedValue]

    /// Keys present in both snapshots whose value or provenance changed.
    public let modified: [ModifiedValue]

    /// Whether there are no differences between the snapshots.
    public var isEmpty: Bool {
        added.isEmpty && removed.isEmpty && modified.isEmpty
    }
}
