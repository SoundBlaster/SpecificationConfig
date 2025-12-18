import SwiftUI

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

            if let config = configManager.config {
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

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Task E4 complete: Split view UI + Reload")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Next: E5 - Error list panel")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .font(.body)
    }

    private var rightPanel: some View {
        VStack(spacing: 16) {
            if let config = configManager.config {
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
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
}
