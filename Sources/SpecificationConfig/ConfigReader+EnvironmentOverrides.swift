import Configuration
import Foundation

public extension ConfigReader {
    /// Creates a reader that prefers environment variables over provided values.
    ///
    /// - Parameters:
    ///   - values: In-memory configuration values, typically loaded from files.
    ///   - environmentVariables: Environment dictionary used for overrides.
    /// - Returns: A config reader with env-first precedence.
    static func withEnvironmentOverrides(
        values: [AbsoluteConfigKey: ConfigValue],
        environmentVariables: [String: String] = ProcessInfo.processInfo.environment
    ) -> ConfigReader {
        let envProvider = EnvironmentVariablesProvider(environmentVariables: environmentVariables)
        let inMemoryProvider = InMemoryProvider(values: values)
        return ConfigReader(providers: [envProvider, inMemoryProvider])
    }
}
