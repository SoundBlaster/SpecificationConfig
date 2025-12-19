HStack {
    Text("Context:")
        .fontWeight(.semibold)
    Text(configManager.contextDescription)
        .font(.subheadline)
        .foregroundColor(.secondary)
}

Button(configManager.isNightOverrideActive ? "Clear Night Override" : "Force Night Mode") {
    configManager.toggleNightMode()
}
.buttonStyle(.bordered)
.tint(configManager.isNightOverrideActive ? .yellow : nil)
