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
/// Captures all resolved values, their provenance, and any diagnostics
/// generated during the build process. Snapshots provide visibility into
/// where configuration came from and what issues occurred.
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

    /// When this snapshot was created
    public let timestamp: Date

    /// Diagnostic messages collected during configuration resolution.
    ///
    /// Contains errors, warnings, and informational messages with context
    /// about what went wrong and where.
    public let diagnostics: DiagnosticsReport

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
    ///   - timestamp: When the snapshot was created (default: now)
    ///   - diagnostics: Collected diagnostics (default: empty report)
    public init(
        resolvedValues: [ResolvedValue] = [],
        timestamp: Date = Date(),
        diagnostics: DiagnosticsReport = DiagnosticsReport()
    ) {
        self.resolvedValues = resolvedValues
        self.timestamp = timestamp
        self.diagnostics = diagnostics
    }

    /// Finds a resolved value by key.
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
        resolvedValues.first { $0.key == key }
    }
}
