import Configuration
import SpecificationCore

/// A type-erased binding that can store `Binding<Draft, Value>` instances with
/// different `Value` types in a homogeneous collection.
///
/// `AnyBinding` wraps a `Binding` and erases its `Value` type parameter, allowing
/// you to create arrays like `[AnyBinding<AppDraft>]` containing bindings for
/// String, Int, Bool, URL, etc.
///
/// Example:
/// ```swift
/// struct AppDraft {
///     var name: String?
///     var port: Int?
///     var enabled: Bool?
/// }
///
/// let nameBinding = Binding<AppDraft, String>(
///     key: "app.name",
///     keyPath: \AppDraft.name,
///     decoder: { reader, key in try? reader.get(key) }
/// )
///
/// let portBinding = Binding<AppDraft, Int>(
///     key: "app.port",
///     keyPath: \AppDraft.port,
///     decoder: { reader, key in try? reader.get(key) }
/// )
///
/// // Store heterogeneous bindings in a single array
/// let bindings: [AnyBinding<AppDraft>] = [
///     AnyBinding(nameBinding),
///     AnyBinding(portBinding)
/// ]
///
/// // Apply all bindings to a draft
/// var draft = AppDraft()
/// for binding in bindings {
///     try binding.apply(to: &draft, reader: configReader)
/// }
/// ```
public struct AnyBinding<Draft> {
    /// The configuration key this binding reads from.
    public let key: String

    /// Type-erased application closure.
    /// Decodes the value, validates it, and writes to the draft.
    private let _apply: (inout Draft, Configuration.ConfigReader) throws -> Void

    /// Creates a type-erased binding from a concrete `Binding`.
    ///
    /// - Parameter binding: The binding to wrap and type-erase
    public init<Value>(_ binding: Binding<Draft, Value>) {
        self.key = binding.key
        self._apply = { draft, reader in
            // Decode the value
            let decodedValue = try binding.decoder(reader, binding.key)

            // Use default if needed
            let valueToValidate = decodedValue ?? binding.defaultValue

            // If we have a value, validate and write it
            if let value = valueToValidate {
                // Run all value specs
                for spec in binding.valueSpecs {
                    if !spec.isSatisfiedBy(value) {
                        // For now, throw a simple error (B4 will add proper types)
                        throw ConfigError.specFailed(key: binding.key)
                    }
                }

                // Write validated value to draft
                draft[keyPath: binding.keyPath] = value
            }
            // If no value and no default, leave draft field as nil (valid)
        }
    }

    /// Applies this binding to a draft by reading from the config reader.
    ///
    /// - Parameters:
    ///   - draft: The draft configuration object to mutate
    ///   - reader: The configuration reader to read values from
    /// - Throws: Decode errors or validation failures
    public func apply(to draft: inout Draft, reader: Configuration.ConfigReader) throws {
        try _apply(&draft, reader)
    }
}

/// Temporary error type for B2 (will be replaced by proper Diagnostics in B4)
public enum ConfigError: Error {
    case specFailed(key: String)
}
