private var rightPanel: some View {
    VStack(spacing: 16) {
        if let config = configManager.effectiveConfig {
            Text(config.petName)
                .font(.system(size: 48, weight: .bold))

            Image(systemName: config.isSleeping ? "moon.zzz.fill" : "sun.max.fill")
                .font(.system(size: 56))
                .foregroundColor(config.isSleeping ? .purple : .orange)

            Text(config.isSleeping ? "Sleeping peacefully" : "Wide awake and playful")
                .font(.title3)
                .foregroundColor(.secondary)
        } else {
            Text("No pet loaded")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Reload after updating config.json")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

private var failureDiagnostics: [DiagnosticItem]? {
    guard case let .failure(diagnostics, _) = configManager.buildResult else {
        return nil
    }
    guard !diagnostics.diagnostics.isEmpty else { return nil }
    return diagnostics.diagnostics
}

private func severityColor(_ severity: DiagnosticSeverity) -> Color {
    switch severity {
    case .error:
        .red
    case .warning:
        .orange
    case .info:
        .blue
    }
}

private func specDisplayName(for item: DiagnosticItem) -> String? {
    item.context["spec"]?.displayValue
}

private func specTypeName(for item: DiagnosticItem) -> String? {
    item.context["specType"]?.displayValue
}

private func provenanceDescription(_ provenance: Provenance) -> String {
    switch provenance {
    case let .fileProvider(name):
        "File: \(name)"
    case .environmentVariable:
        "Environment"
    case .defaultValue:
        "Default value"
    case .decisionFallback:
        "Decision fallback"
    case .unknown:
        "Unknown"
    }
}

private func decisionTraceDescription(_ trace: DecisionTrace) -> String {
    "\(trace.decisionName) (\(trace.decisionType)) - index \(trace.matchedIndex)"
}
