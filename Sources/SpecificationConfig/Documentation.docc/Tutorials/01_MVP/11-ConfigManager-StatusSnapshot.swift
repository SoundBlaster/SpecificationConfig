import SpecificationConfig

extension ConfigManager {
    var statusDescription: String {
        if let error = loadError {
            "Error: \(error.localizedDescription)"
        } else if let buildResult {
            switch buildResult {
            case .success:
                "Config built successfully"
            case let .failure(diagnostics, _):
                "Config build failed (\(diagnostics.errorCount) errors)"
            }
        } else if reader != nil {
            "Config loaded successfully"
        } else {
            "No config loaded"
        }
    }

    var snapshot: Snapshot? {
        buildResult?.snapshot
    }

    var resolvedValues: [ResolvedValue] {
        snapshot?.resolvedValues ?? []
    }

    var decisionTraces: [DecisionTrace] {
        snapshot?.decisionTraces ?? []
    }

    var snapshotTimestampDescription: String? {
        guard let timestamp = snapshot?.timestamp else { return nil }
        return Self.snapshotDateFormatter.string(from: timestamp)
    }

    private static let snapshotDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
