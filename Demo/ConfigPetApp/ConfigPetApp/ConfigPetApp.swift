import SwiftUI

@main
struct ConfigPetApp: App {
    @StateObject private var configManager = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
        .defaultSize(width: 800, height: 600)
    }
}
