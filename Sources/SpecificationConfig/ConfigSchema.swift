import Configuration

/// Declares expected configuration keys and validates their presence before binding.
///
/// Use `ConfigSchema` as a pre-flight check to verify that all required keys
/// exist in the configuration provider before running the full pipeline.
///
/// ## Example
///
/// ```swift
/// let schema = ConfigSchema(requirements: [
///     .required("pet.name", check: .string),
///     .required("pet.age", check: .int),
///     .optional("pet.color"),
/// ])
///
/// let diagnostics = schema.validate(reader: reader)
/// if diagnostics.hasErrors {
///     for item in diagnostics.diagnostics {
///         print(item.formattedDescription())
///     }
/// }
/// ```
public struct ConfigSchema: Sendable {
    /// How to check whether a key is present in the configuration.
    public struct KeyCheck: Sendable {
        let check: @Sendable (ConfigReader, String) -> Bool

        /// Check by reading as a string value.
        public static let string = KeyCheck { reader, key in
            reader.string(forKey: ConfigKey(key)) != nil
        }

        /// Check by reading as an integer value.
        public static let int = KeyCheck { reader, key in
            reader.int(forKey: ConfigKey(key)) != nil
        }

        /// Check by reading as a boolean value.
        public static let bool = KeyCheck { reader, key in
            reader.bool(forKey: ConfigKey(key)) != nil
        }

        /// Check by reading as a double value.
        public static let double = KeyCheck { reader, key in
            reader.double(forKey: ConfigKey(key)) != nil
        }

        /// Check using a custom predicate.
        public static func custom(
            _ predicate: @Sendable @escaping (ConfigReader, String) -> Bool
        ) -> KeyCheck {
            KeyCheck(check: predicate)
        }
    }

    /// A single key requirement in the schema.
    public struct KeyRequirement: Sendable {
        /// The configuration key.
        public let key: String

        /// Whether this key must be present.
        public let isRequired: Bool

        /// How to check for key presence.
        let keyCheck: KeyCheck

        /// Creates a requirement for a key that must exist.
        ///
        /// - Parameters:
        ///   - key: The configuration key.
        ///   - check: How to check for presence (default: `.string`).
        public static func required(_ key: String, check: KeyCheck = .string) -> KeyRequirement {
            KeyRequirement(key: key, isRequired: true, keyCheck: check)
        }

        /// Creates a requirement for a key that may be absent.
        public static func optional(_ key: String) -> KeyRequirement {
            KeyRequirement(key: key, isRequired: false, keyCheck: .string)
        }
    }

    /// The declared key requirements.
    public let requirements: [KeyRequirement]

    /// Creates a schema with the given key requirements.
    public init(requirements: [KeyRequirement]) {
        self.requirements = requirements
    }

    /// Validates that all required keys exist in the configuration reader.
    ///
    /// Returns a diagnostics report containing an error for each required key
    /// that is missing from the configuration provider.
    ///
    /// - Parameter reader: The configuration reader to validate against.
    /// - Returns: A diagnostics report with errors for missing required keys.
    public func validate(reader: ConfigReader) -> DiagnosticsReport {
        var diagnostics = DiagnosticsReport()
        for requirement in requirements where requirement.isRequired {
            if !requirement.keyCheck.check(reader, requirement.key) {
                diagnostics.add(DiagnosticItem(
                    key: requirement.key,
                    severity: .error,
                    message: "Required key '\(requirement.key)' is missing from configuration"
                ))
            }
        }
        return diagnostics
    }
}
