Button(configManager.isNightOverrideActive ? "Clear Night Override" : "Force Night Mode") {
    configManager.toggleNightMode()
}
.buttonStyle(.bordered)
.tint(configManager.isNightOverrideActive ? .yellow : nil)

Button("Reload") {
    configManager.loadConfig()
}
.buttonStyle(.borderedProminent)

Button("Wake up for 10s") {
    configManager.triggerSleepOverride()
}
.buttonStyle(.bordered)
.disabled(configManager.effectiveConfig == nil || configManager.isSleepOverrideActive)

if configManager.isSleepOverrideActive {
    Text("Temporary sleep override active")
        .font(.caption)
        .foregroundColor(.secondary)
}
