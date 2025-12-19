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
