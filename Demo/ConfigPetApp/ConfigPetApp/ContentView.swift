import Configuration
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Config Pet")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Demo application for SpecificationConfig")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 12) {
                // Config status
                HStack {
                    Text("Config Status:")
                        .fontWeight(.semibold)
                    Text(configManager.statusDescription)
                        .foregroundColor(configManager.loadError != nil ? .red : .green)
                }

                // Show loaded values if available
                if let reader = configManager.reader {
                    Divider()

                    Text("Loaded Configuration:")
                        .fontWeight(.semibold)

                    if let petName = reader.string(forKey: ConfigKey("pet.name")) {
                        HStack {
                            Text("Pet Name:")
                            Text(petName)
                                .foregroundColor(.blue)
                        }
                    }

                    if let isSleeping = reader.bool(forKey: ConfigKey("pet.isSleeping")) {
                        HStack {
                            Text("Is Sleeping:")
                            Text(isSleeping ? "Yes" : "No")
                                .foregroundColor(isSleeping ? .purple : .orange)
                        }
                    }
                }
            }
            .font(.body)

            Spacer()

            VStack(spacing: 8) {
                Text("Task E2 complete: Config file loading")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Next: E3 - AppConfig types and SpecProfile")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
}
