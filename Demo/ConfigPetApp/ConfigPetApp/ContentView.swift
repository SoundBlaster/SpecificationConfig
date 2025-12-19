import SpecificationConfig
import SwiftUI

/// Main UI for the Config Pet demo.
struct ContentView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(minWidth: 280, idealWidth: 360, maxWidth: 420)
                .padding(32)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            Divider()

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Summary, reload controls, and diagnostics list.
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Config Pet")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Demo application for SpecificationConfig")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Config Status:")
                    .fontWeight(.semibold)
                Text(configManager.statusDescription)
                    .foregroundColor(configManager.loadError != nil ? .red : .green)
            }

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

            if let config = configManager.effectiveConfig {
                Divider()

                Text("Loaded Configuration:")
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pet Name:")
                        Text(config.petName)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Is Sleeping:")
                        Text(config.isSleeping ? "Yes" : "No")
                            .foregroundColor(config.isSleeping ? .purple : .orange)
                    }
                }
            }

            if let diagnostics = failureDiagnostics {
                Divider()

                Text("Configuration Errors")
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(diagnostics.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(severityColor(item.severity))
                                    .frame(width: 8, height: 8)
                                Text(item.key ?? "General")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text(item.formattedDescription())
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            if let specName = specDisplayName(for: item) {
                                Text("Spec: \(specName)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            if let specType = specTypeName(for: item) {
                                Text("Type: \(specType)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color(.windowBackgroundColor).opacity(0.6))
                        .cornerRadius(8)
                    }
                }
            }

            if !configManager.resolvedValues.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Resolved Values")
                            .fontWeight(.semibold)
                        Spacer()
                        if let timestamp = configManager.snapshotTimestampDescription {
                            Text("Snapshot: \(timestamp)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(configManager.resolvedValues, id: \.key) { value in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(value.key)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value.displayValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }

                                Text("Source: \(provenanceDescription(value.provenance))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(.windowBackgroundColor).opacity(0.4))
                            .cornerRadius(6)
                        }
                    }
                }
            }

            if !configManager.decisionTraces.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Decision Trace")
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(configManager.decisionTraces.enumerated()), id: \.offset) { _, trace in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trace.key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(decisionTraceDescription(trace))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(.windowBackgroundColor).opacity(0.4))
                            .cornerRadius(6)
                        }
                    }
                }
            }

            Spacer()
        }
        .font(.body)
    }

    /// The pet display based on the resolved configuration.
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

    /// Filters build diagnostics down to error items, if present.
    private var failureDiagnostics: [DiagnosticItem]? {
        guard case let .failure(diagnostics, _) = configManager.buildResult else {
            return nil
        }
        guard !diagnostics.diagnostics.isEmpty else { return nil }
        return diagnostics.diagnostics
    }

    /// Maps diagnostic severity to a UI color.
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
        "\(trace.decisionName) (\(trace.decisionType)) · index \(trace.matchedIndex)"
    }
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
}
