import Foundation

extension WatchingProvider {
    func startWatching(interval: TimeInterval = 1) {
        provider.start { _ in }
        provider.setPollingInterval(interval)
    }

    func stopWatching() {
        provider.stop()
    }
}
