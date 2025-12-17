import Foundation

/// Severity level for diagnostic messages.
///
/// Diagnostics can be errors (build failures), warnings (potential issues),
/// or informational messages (debug/audit trail). Ordering is deterministic:
/// `.error` < `.warning` < `.info`.
public enum DiagnosticSeverity: String, Sendable, Equatable, Comparable {
    /// Critical error that prevents configuration build.
    case error

    /// Warning about potential issues (non-blocking).
    case warning

    /// Informational message for debugging/audit.
    case info

    public static func < (lhs: DiagnosticSeverity, rhs: DiagnosticSeverity) -> Bool {
        orderingIndex(lhs) < orderingIndex(rhs)
    }

    private static func orderingIndex(_ severity: DiagnosticSeverity) -> Int {
        switch severity {
        case .error:
            return 0
        case .warning:
            return 1
        case .info:
            return 2
        }
    }
}

/// Contextual value associated with a diagnostic, with redaction support.
///
/// Use this type when attaching optional metadata (expected/actual values,
/// provider names, etc.) to diagnostics. Values marked as secret will use
/// the global `Redaction` utility to hide sensitive information.
public struct DiagnosticContextValue: Sendable, Equatable {
    /// The original value for diagnostic context.
    public let rawValue: String

    /// Whether this value should be redacted in displays.
    public let isSecret: Bool

    /// The redacted or plain value suitable for display.
    public var displayValue: String {
        Redaction.redact(rawValue, isSecret: isSecret)
    }

    /// Creates a context value.
    ///
    /// - Parameters:
    ///   - rawValue: The underlying value to display.
    ///   - isSecret: Whether the value should be redacted (default: false).
    public init(_ rawValue: String, isSecret: Bool = false) {
        self.rawValue = rawValue
        self.isSecret = isSecret
    }
}

/// A single diagnostic message with optional context and redaction.
///
/// Represents an error, warning, or informational message encountered
/// during configuration resolution. Includes the configuration key,
/// severity, descriptive message, and optional context for display.
public struct DiagnosticItem: Sendable, Equatable {
    /// The configuration key this diagnostic relates to (if applicable).
    public let key: String?

    /// The severity level of this diagnostic.
    public let severity: DiagnosticSeverity

    /// Human-readable description of the issue.
    public let message: String

    /// Whether the message contains sensitive data that should be redacted.
    public let isMessageRedacted: Bool

    /// Additional contextual values that may require redaction.
    public let context: [String: DiagnosticContextValue]

    /// The display-ready message with optional redaction applied.
    public var displayMessage: String {
        Redaction.redact(message, isSecret: isMessageRedacted)
    }

    /// Concise, deterministic context summary (keys sorted alphabetically).
    public var contextSummary: String? {
        guard !context.isEmpty else { return nil }

        let ordered = context.sorted { lhs, rhs in lhs.key < rhs.key }
        let parts = ordered.map { key, value in "\(key)=\(value.displayValue)" }
        return parts.joined(separator: ", ")
    }

    /// A formatted description combining the redacted message and context.
    ///
    /// - Parameter includeContext: Whether to append context information.
    /// - Returns: The formatted description.
    public func formattedDescription(includeContext: Bool = true) -> String {
        guard includeContext, let summary = contextSummary else {
            return displayMessage
        }
        return "\(displayMessage) (\(summary))"
    }

    /// Creates a diagnostic item.
    ///
    /// - Parameters:
    ///   - key: The configuration key (optional).
    ///   - severity: The severity level.
    ///   - message: Description of the issue.
    ///   - isMessageRedacted: Whether the message contains secrets and should be redacted.
    ///   - context: Optional contextual values (e.g., expected/actual), with per-value redaction.
    public init(
        key: String? = nil,
        severity: DiagnosticSeverity,
        message: String,
        isMessageRedacted: Bool = false,
        context: [String: DiagnosticContextValue] = [:]
    ) {
        self.key = key
        self.severity = severity
        self.message = message
        self.isMessageRedacted = isMessageRedacted
        self.context = context
    }
}

/// Collection of diagnostic messages from configuration resolution.
///
/// Collects errors, warnings, and informational messages in a deterministic
/// order. Provides convenience methods to check for errors or warnings.
public struct DiagnosticsReport: Sendable, Equatable {
    /// All diagnostic items, stored in insertion order.
    private var items: [DiagnosticItem]

    /// All diagnostic items in deterministic order.
    ///
    /// Items are sorted by:
    /// 1. Key (alphabetically, with nil keys last)
    /// 2. Severity (errors before warnings before info)
    /// 3. Display message (alphabetically, post-redaction)
    /// 4. Context summary (alphabetically by context key)
    public var diagnostics: [DiagnosticItem] {
        items.sorted { lhs, rhs in
            switch (lhs.key, rhs.key) {
            case (nil, nil):
                break
            case (nil, _):
                return false
            case (_, nil):
                return true
            case let (lhsKey?, rhsKey?):
                if lhsKey != rhsKey {
                    return lhsKey < rhsKey
                }
            }

            if lhs.severity != rhs.severity {
                return lhs.severity < rhs.severity
            }

            if lhs.displayMessage != rhs.displayMessage {
                return lhs.displayMessage < rhs.displayMessage
            }

            return (lhs.contextSummary ?? "") < (rhs.contextSummary ?? "")
        }
    }

    /// Whether this report contains any errors.
    public var hasErrors: Bool {
        items.contains { $0.severity == .error }
    }

    /// Whether this report contains any warnings.
    public var hasWarnings: Bool {
        items.contains { $0.severity == .warning }
    }

    /// Number of error diagnostics.
    public var errorCount: Int {
        items.filter { $0.severity == .error }.count
    }

    /// Number of warning diagnostics.
    public var warningCount: Int {
        items.filter { $0.severity == .warning }.count
    }

    /// Number of info diagnostics.
    public var infoCount: Int {
        items.filter { $0.severity == .info }.count
    }

    /// Total number of diagnostics.
    public var count: Int {
        items.count
    }

    /// Whether this report is empty.
    public var isEmpty: Bool {
        items.isEmpty
    }

    /// Creates an empty diagnostics report.
    public init() {
        items = []
    }

    /// Creates a diagnostics report with initial items.
    ///
    /// - Parameter items: Initial diagnostic items.
    public init(items: [DiagnosticItem]) {
        self.items = items
    }

    /// Adds a diagnostic item to the report.
    ///
    /// - Parameter item: The diagnostic item to add.
    public mutating func add(_ item: DiagnosticItem) {
        items.append(item)
    }

    /// Adds a diagnostic with individual components.
    ///
    /// - Parameters:
    ///   - key: The configuration key (optional).
    ///   - severity: The severity level.
    ///   - message: Description of the issue.
    ///   - isMessageRedacted: Whether the message contains secrets.
    ///   - context: Optional contextual values.
    public mutating func add(
        key: String? = nil,
        severity: DiagnosticSeverity,
        message: String,
        isMessageRedacted: Bool = false,
        context: [String: DiagnosticContextValue] = [:]
    ) {
        let item = DiagnosticItem(
            key: key,
            severity: severity,
            message: message,
            isMessageRedacted: isMessageRedacted,
            context: context
        )
        add(item)
    }

    /// Merges another diagnostics report into this one.
    ///
    /// - Parameter other: The report to merge.
    public mutating func merge(_ other: DiagnosticsReport) {
        items.append(contentsOf: other.items)
    }

    public static func == (lhs: DiagnosticsReport, rhs: DiagnosticsReport) -> Bool {
        lhs.diagnostics == rhs.diagnostics
    }
}
