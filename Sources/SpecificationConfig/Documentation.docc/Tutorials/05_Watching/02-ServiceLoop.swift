import Foundation

/// A lightweight loop that reloads configuration when files change.
actor WatchingServiceLoop {
    private var reloadTask: Task<Void, Never>?

    func start(interval: TimeInterval = 1) {
        reloadTask?.cancel()
        reloadTask = Task.detached { [interval] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                self.reloadConfiguration()
            }
        }
    }

    func stop() {
        reloadTask?.cancel()
        reloadTask = nil
    }

    private func reloadConfiguration() {
        // Trigger ConfigManager.reloadConfig or similar
    }
}
