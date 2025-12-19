import Configuration

let envProvider = EnvironmentVariablesProvider(environmentVariables: environmentVariables)
let inMemoryProvider = InMemoryProvider(name: inMemoryProviderName, values: values)
