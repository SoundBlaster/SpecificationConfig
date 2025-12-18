import Configuration
import Foundation

/// Convenience helpers for reading primitive configuration values.
///
/// These helpers simplify decoder implementations by eliminating boilerplate
/// for common primitive types. They can be used directly as decoder functions
/// in Binding definitions.
///
/// ## Example
///
/// ```swift
/// // Before (manual)
/// let nameBinding = Binding(
///     key: "app.name",
///     keyPath: \Draft.name,
///     decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
/// )
///
/// // After (with helper)
/// let nameBinding = Binding(
///     key: "app.name",
///     keyPath: \Draft.name,
///     decoder: ConfigReader.string
/// )
/// ```
public extension ConfigReader {
    /// Reads a string value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The string value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    static func string(_ reader: ConfigReader, _ key: String) throws -> String? {
        reader.string(forKey: ConfigKey(key))
    }

    /// Reads a boolean value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The boolean value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    static func bool(_ reader: ConfigReader, _ key: String) throws -> Bool? {
        reader.bool(forKey: ConfigKey(key))
    }

    /// Reads an integer value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The integer value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    static func int(_ reader: ConfigReader, _ key: String) throws -> Int? {
        reader.int(forKey: ConfigKey(key))
    }
}
