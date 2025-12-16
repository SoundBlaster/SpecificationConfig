import Configuration
import SpecificationCore

/// A binding that maps a configuration key to a field in a Draft configuration object.
///
/// `Binding` encapsulates:
/// - The configuration key to read
/// - Where to write the decoded value (via KeyPath)
/// - How to decode the raw config value into a typed `Value`
/// - An optional default value
/// - Value-level validation specs from SpecificationCore
/// - Whether the value should be redacted in diagnostics (secrets)
///
/// Example:
/// ```swift
/// struct AppDraft {
///     var serverURL: URL?
///     var timeout: Int?
/// }
///
/// let binding = Binding(
///     key: "server.url",
///     keyPath: \AppDraft.serverURL,
///     decoder: { reader, key in
///         guard let urlString: String = try reader.get(key) else { return nil }
///         return URL(string: urlString)
///     },
///     defaultValue: URL(string: "https://example.com")
/// )
/// ```
public struct Binding<Draft, Value> {
    /// The configuration key to read from the config provider.
    public let key: String

    /// The writable key path pointing to where this value should be stored in the Draft.
    public let keyPath: WritableKeyPath<Draft, Value?>

    /// The decoder closure that reads and transforms the config value.
    ///
    /// This closure receives a `ConfigReader` and the key string, and should return
    /// the decoded value or `nil` if the key doesn't exist. It can throw errors if
    /// decoding fails.
    public let decoder: (Configuration.ConfigReader, String) throws -> Value?

    /// The default value to use if the key is not found in configuration.
    public let defaultValue: Value?

    /// Value-level validation specs to run on the decoded value.
    ///
    /// These specs are from SpecificationCore and validate individual values before
    /// they're written to the Draft. Empty array means no validation.
    public let valueSpecs: [AnySpecification<Value>]

    /// Whether this value is a secret and should be redacted in diagnostics.
    ///
    /// When `true`, the value will be replaced with `[REDACTED]` in logs, snapshots,
    /// and error messages. Use this for passwords, API keys, tokens, etc.
    public let isSecret: Bool

    /// Creates a binding with all parameters.
    ///
    /// - Parameters:
    ///   - key: The configuration key to read
    ///   - keyPath: Where to write the decoded value in the Draft
    ///   - decoder: Closure to decode the config value
    ///   - defaultValue: Optional default value if key is missing
    ///   - valueSpecs: Validation specs to apply to the decoded value
    ///   - isSecret: Whether to redact this value in diagnostics
    public init(
        key: String,
        keyPath: WritableKeyPath<Draft, Value?>,
        decoder: @escaping (Configuration.ConfigReader, String) throws -> Value?,
        defaultValue: Value? = nil,
        valueSpecs: [AnySpecification<Value>] = [],
        isSecret: Bool = false
    ) {
        self.key = key
        self.keyPath = keyPath
        self.decoder = decoder
        self.defaultValue = defaultValue
        self.valueSpecs = valueSpecs
        self.isSecret = isSecret
    }
}
