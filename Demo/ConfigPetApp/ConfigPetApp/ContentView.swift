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
                        }
                        .padding(8)
                        .background(Color(.windowBackgroundColor).opacity(0.6))
                        .cornerRadius(8)
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
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
}
