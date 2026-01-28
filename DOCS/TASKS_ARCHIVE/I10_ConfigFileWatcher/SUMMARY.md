# I10 — Config File Watcher Integration

**Status:** Completed
**Archived:** 2026-01-28

## Summary

Added `ConfigFileWatcher` actor for automatic detection of configuration file changes via modification-date polling. Provides a lightweight alternative to the Configuration framework's `ReloadingFileProvider` without requiring heavy dependencies.

## Changes

### New Files
- `Sources/SpecificationConfig/ConfigFileWatcher.swift` — Actor with `start(onChange:)` and `stop()` methods
- `Tests/SpecificationConfigTests/ConfigFileWatcherTests.swift` — 6 tests

### Design Decisions
- **Actor-based**: Thread-safe by construction, fits Swift 6 strict concurrency model.
- **Modification-date polling**: Uses `FileManager.attributesOfItem` to compare modification dates. Simple, reliable, no DispatchSource complexity.
- **`Duration`-based interval**: Configurable poll interval using `Duration` (default: 1 second), consistent with `ContinuousClock` usage elsewhere.
- **`@Sendable async` callback**: Allows callers to dispatch to their own actors or MainActor from the onChange handler.
- **Composable**: Not coupled to `ConfigLoader` — users wire the callback to their own reload logic.

## Validation
- 167 tests passing
- swiftformat lint clean
- swift build clean
