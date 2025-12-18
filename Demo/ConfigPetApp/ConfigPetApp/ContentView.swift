import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Config Pet")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Demo application for SpecificationConfig")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 8) {
                Text("Configuration loading will be added in task E2")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Current status: App scaffolding complete (E1)")
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
}
