import Foundation

/// Monitors a configuration file for changes using modification-date polling.
///
/// Use `ConfigFileWatcher` to detect when a configuration file has been
/// modified on disk and trigger a reload automatically.
///
/// ## Example
///
/// ```swift
/// let watcher = ConfigFileWatcher(
///     fileURL: URL(fileURLWithPath: "/path/to/config.json"),
///     pollInterval: .seconds(2)
/// )
///
/// await watcher.start {
///     // File changed — reload configuration
///     let result = loader.reload()
///     // ...
/// }
///
/// // Later, stop watching
/// await watcher.stop()
/// ```
///
/// ## Thread Safety
///
/// `ConfigFileWatcher` is an actor and is safe to use from any context.
/// The `onChange` callback runs on the actor's executor; use `@MainActor`
/// dispatch inside the callback if UI updates are needed.
public actor ConfigFileWatcher {
    private let fileURL: URL
    private let pollInterval: Duration
    private var watchTask: Task<Void, Never>?
    private var lastModificationDate: Date?

    /// Whether the watcher is currently monitoring the file.
    public var isWatching: Bool {
        watchTask != nil
    }

    /// Creates a file watcher for the specified URL.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL to monitor for changes.
    ///   - pollInterval: How often to check for modifications (default: 1 second).
    public init(fileURL: URL, pollInterval: Duration = .seconds(1)) {
        self.fileURL = fileURL
        self.pollInterval = pollInterval
    }

    /// Starts monitoring the file for changes.
    ///
    /// Cancels any previous watching session before starting a new one.
    /// The `onChange` callback is called each time the file's modification
    /// date changes.
    ///
    /// - Parameter onChange: A sendable async closure called when the file changes.
    public func start(onChange: @escaping @Sendable () async -> Void) {
        stop()
        lastModificationDate = modificationDate()
        let interval = pollInterval
        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { break }
                guard let self else { break }
                let current = await checkForChange()
                if current {
                    await onChange()
                }
            }
        }
    }

    /// Stops monitoring the file.
    public func stop() {
        watchTask?.cancel()
        watchTask = nil
    }

    // MARK: - Private

    private func checkForChange() -> Bool {
        let current = modificationDate()
        if current != lastModificationDate {
            lastModificationDate = current
            return true
        }
        return false
    }

    private nonisolated func modificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(
            atPath: fileURL.path
        )[.modificationDate] as? Date
    }
}
