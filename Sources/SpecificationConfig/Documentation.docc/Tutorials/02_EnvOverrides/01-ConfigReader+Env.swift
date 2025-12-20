import Configuration
import Foundation

public extension ConfigReader {
    /// Creates a reader that prefers environment variables over provided values.
    ///
    /// - Parameters:
    ///   - values: In-memory configuration values, typically loaded from files.
    ///   - environmentVariables: Environment dictionary used for overrides.
    ///   - accessReporter: Optional reporter that observes configuration accesses.
    ///   - inMemoryProviderName: Optional label for the in-memory provider, useful when identifying file-based sources.
    /// - Returns: A config reader with env-first precedence.
    static func withEnvironmentOverrides(
        values: [AbsoluteConfigKey: ConfigValue],
        environmentVariables: [String: String] = ProcessInfo.processInfo.environment,
        accessReporter: (any AccessReporter)? = nil,
        inMemoryProviderName: String? = nil
    ) -> ConfigReader {
        let envProvider = EnvironmentVariablesProvider(environmentVariables: environmentVariables)
        let inMemoryProvider = InMemoryProvider(name: inMemoryProviderName, values: values)
        return ConfigReader(
            providers: [envProvider, inMemoryProvider],
            accessReporter: accessReporter
        )
    }
}
