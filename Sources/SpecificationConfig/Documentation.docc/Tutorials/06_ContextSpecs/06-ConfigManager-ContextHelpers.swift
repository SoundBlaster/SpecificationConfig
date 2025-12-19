extension ConfigManager {
    var contextDescription: String {
        DemoContextProvider.shared.contextSummary
    }

    var isNightOverrideActive: Bool {
        DemoContextProvider.shared.isNightOverrideActive
    }

    func toggleNightMode() {
        DemoContextProvider.shared.toggleNightOverride()
        rebuildConfig()
    }

    private func rebuildConfig() {
        guard let existingReader = reader else { return }
        build(with: existingReader, provenanceReporter: provenanceReporter)
    }
}
