import SwiftUI

extension ContentView {
    var leftPanel: some View {
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
        }
    }
}
