import Configuration
import Foundation

/// Demonstrates a reloading provider that watches `config.json`.
final class WatchingProvider {
    private let provider: ReloadingFileProvider<JSONSnapshot>

    init(configFileURL: URL) {
        provider = ReloadingFileProvider<JSONSnapshot>(fileURL: configFileURL) {
            JSONDecoder().decode(JSONSnapshot.self, from: try Data(contentsOf: $0))
        }
    }

    func startWatching(interval: TimeInterval = 1) {
        provider.start() { _ in }
        provider.setPollingInterval(interval)
    }

    func stopWatching() {
        provider.stop()
    }
}
