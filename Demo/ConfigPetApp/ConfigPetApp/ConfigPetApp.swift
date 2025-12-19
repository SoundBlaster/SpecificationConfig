import SwiftUI

/// App entry point for the Config Pet demo.
@main
struct ConfigPetApp: App {
    /// Shared configuration manager for the demo UI.
    @StateObject private var configManager = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
        .defaultSize(width: 800, height: 600)
    }
}
