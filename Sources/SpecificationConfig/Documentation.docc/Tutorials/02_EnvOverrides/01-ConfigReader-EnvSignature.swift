import Configuration
import Foundation

public extension ConfigReader {
    static func withEnvironmentOverrides(
        values: [AbsoluteConfigKey: ConfigValue],
        environmentVariables: [String: String] = ProcessInfo.processInfo.environment,
        accessReporter: (any AccessReporter)? = nil,
        inMemoryProviderName: String? = nil
    ) -> ConfigReader {
        _ = environmentVariables
        let inMemoryProvider = InMemoryProvider(name: inMemoryProviderName, values: values)
        return ConfigReader(
            providers: [inMemoryProvider],
            accessReporter: accessReporter
        )
    }
}
