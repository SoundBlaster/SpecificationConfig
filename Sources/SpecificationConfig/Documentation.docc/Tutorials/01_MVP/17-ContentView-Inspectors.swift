if !configManager.overrideEntries.isEmpty {
    Divider()

    VStack(alignment: .leading, spacing: 6) {
        Text("Overrides")
            .fontWeight(.semibold)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(configManager.overrideEntries) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.key)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(entry.value)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }

                    Text(entry.source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(.windowBackgroundColor).opacity(0.4))
                .cornerRadius(6)
            }
        }
    }
} else {
    Divider()

    VStack(alignment: .leading, spacing: 6) {
        Text("Overrides")
            .fontWeight(.semibold)

        Text("No manual overrides active")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    .padding(.top, 4)
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
