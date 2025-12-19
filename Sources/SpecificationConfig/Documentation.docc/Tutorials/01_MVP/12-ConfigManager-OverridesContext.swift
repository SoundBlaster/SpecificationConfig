import SpecificationConfig

@Published private var sleepOverride: Bool?
private var sleepOverrideTask: Task<Void, Never>?

struct OverrideEntry: Identifiable, Sendable {
    let id: String
    let key: String
    let value: String
    let source: String
}

var effectiveConfig: AppConfig? {
    guard let config else { return nil }
    guard let sleepOverride else { return config }
    return AppConfig(petName: config.petName, isSleeping: sleepOverride)
}

var isSleepOverrideActive: Bool {
    sleepOverride != nil
}

func triggerSleepOverride(duration: TimeInterval = 10) {
    guard config != nil else { return }
    sleepOverrideTask?.cancel()
    sleepOverride = false
    sleepOverrideTask = Task { [duration] in
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        await MainActor.run {
            self.sleepOverride = nil
        }
    }
}

var overrideEntries: [OverrideEntry] {
    guard let overrideValue = sleepOverride else {
        return []
    }

    return [
        OverrideEntry(
            id: "pet.isSleeping",
            key: "pet.isSleeping",
            value: overrideValue ? "true" : "false",
            source: "Manual override"
        ),
    ]
}

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
