import Foundation

/// Utilities for redacting sensitive configuration values.
///
/// Use this type to ensure secrets (API keys, passwords, tokens) are
/// consistently hidden in logs, diagnostics, snapshots, and error messages.
///
/// ## Usage
///
/// Mark sensitive bindings with `isSecret: true`:
///
/// ```swift
/// let apiKeyBinding = Binding(
///     key: "api.secret_key",
///     keyPath: \Draft.apiKey,
///     decoder: { reader, key in try reader.get(key) },
///     isSecret: true  // This value will be redacted
/// )
/// ```
///
/// When displaying values, use `Redaction.redact()`:
///
/// ```swift
/// let display = Redaction.redact(apiKey, isSecret: true)
/// print(display) // "[REDACTED]"
/// ```
///
/// ## Best Practices
///
/// **Always mark as secret:**
/// - API keys and tokens
/// - Passwords and passphrases
/// - Private keys and certificates
/// - OAuth client secrets
/// - Database credentials
/// - Encryption keys
///
/// **Usually safe as public:**
/// - Application names
/// - Feature flags (boolean toggles)
/// - Numeric timeouts and limits
/// - Public URLs (without tokens in query strings)
/// - Log levels and debug flags
///
/// **Context-dependent:**
/// - Usernames (may be public or private)
/// - Email addresses (depends on privacy policy)
/// - Server hostnames (may reveal internal infrastructure)
///
/// When in doubt, mark as secret. It's safer to over-redact than to leak secrets.
public enum Redaction {
    /// The standard redaction marker.
    ///
    /// This string replaces secret values in all user-facing output:
    /// logs, diagnostics, snapshots, UI displays, and error messages.
    public static let marker: String = "[REDACTED]"

    /// Redacts a string value if marked as secret.
    ///
    /// - Parameters:
    ///   - value: The string value to potentially redact
    ///   - isSecret: Whether this value should be redacted
    /// - Returns: The redaction marker if secret, otherwise the original value
    ///
    /// ## Example
    ///
    /// ```swift
    /// let publicValue = Redaction.redact("https://api.example.com", isSecret: false)
    /// print(publicValue) // "https://api.example.com"
    ///
    /// let secretValue = Redaction.redact("sk_live_abc123", isSecret: true)
    /// print(secretValue) // "[REDACTED]"
    /// ```
    public static func redact(_ value: String, isSecret: Bool) -> String {
        isSecret ? marker : value
    }

    /// Redacts an optional string value if marked as secret.
    ///
    /// - Parameters:
    ///   - value: The optional string value to potentially redact
    ///   - isSecret: Whether this value should be redacted
    /// - Returns: The redaction marker if secret and non-nil, nil if value is nil, otherwise the original value
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = Redaction.redact(optionalPassword, isSecret: true)
    /// // Returns "[REDACTED]" if password exists, nil if it doesn't
    /// ```
    public static func redact(_ value: String?, isSecret: Bool) -> String? {
        guard let value else { return nil }
        return isSecret ? marker : value
    }
}
