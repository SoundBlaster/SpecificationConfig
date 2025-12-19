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
}
