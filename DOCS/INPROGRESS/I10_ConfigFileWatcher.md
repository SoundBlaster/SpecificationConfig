# I10 — Config File Watcher Integration

**Status:** Planned
**Priority:** Low
**Phase:** I
**Dependencies:** None

## Problem

The demo app and library users currently rely on manual reload (pressing a "Reload" button). There is no library-level utility to automatically detect when a configuration file has changed and trigger a reload.

The Configuration framework provides `ReloadingFileProvider` (behind `#if Reloading` with heavy dependencies: ServiceLifecycle, Logging, Metrics, AsyncAlgorithms), but SpecificationConfig needs a lightweight alternative that integrates with the existing `ConfigLoader` pattern.

## Solution

Add a `ConfigFileWatcher` actor that monitors a configuration file by polling its modification date and notifies a callback when changes are detected.

### API Design

```swift
/// Monitors a configuration file for changes using modification date polling.
public actor ConfigFileWatcher {
    public init(fileURL: URL, pollInterval: Duration = .seconds(1))
    public func start(onChange: @escaping @Sendable () async -> Void)
    public func stop()
    public var isWatching: Bool { get }
}
```

### Design Decisions

1. **Actor-based**: Thread-safe by construction, fits Swift 6 strict concurrency.
2. **Polling with modification date**: Simple, reliable, cross-platform within Apple ecosystem. No DispatchSource complexity.
3. **`Duration`-based interval**: Matches the `ContinuousClock` API used elsewhere in the codebase.
4. **`@Sendable async` callback**: Allows callers to interact with their own actors/MainActor from the callback.
5. **No direct ConfigLoader coupling**: The watcher is composable — users wire it to their own reload logic.

## Implementation

### Files to Create

1. `Sources/SpecificationConfig/ConfigFileWatcher.swift` — Actor implementation
2. `Tests/SpecificationConfigTests/ConfigFileWatcherTests.swift` — Tests

### Test Plan

1. **testStartAndDetectChange** — Start watching a temp file, modify it, verify callback fires
2. **testNoCallbackWithoutChange** — Start watching, wait, verify callback does NOT fire
3. **testStopPreventsCallback** — Start, stop, modify file, verify no callback
4. **testIsWatchingProperty** — Verify isWatching reflects state
5. **testMultipleChangesDetected** — Modify file multiple times, verify multiple callbacks
6. **testRestartWatching** — Stop and restart, verify watching resumes

### Validation

- `swift build` clean
- `swift test` all pass
- `swiftformat --lint .` clean
