return ConfigReader(
    providers: [envProvider, inMemoryProvider],
    accessReporter: accessReporter
)
