# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-01-29

### Added

- **AsyncDecisionBinding** — New type for async predicates enabling database lookups, API calls, and remote feature flags in decision specs.
- **Config Diffing API** — `Snapshot.diff(from:)` method to detect configuration changes (added/removed/modified keys) for reload notifications and UI highlighting.
- **Performance Metrics** — `PerformanceMetrics` in snapshots with binding/spec timing data for troubleshooting slow decoders or validators.
- **Snapshot Lookups Optimization** — Converted `resolvedValues` from array to dictionary for O(1) key lookups.
- **ConfigSchema Validation** — New `ConfigSchema` type to validate required keys before binding resolution.
- **Config File Watcher** — `ConfigLoader.watch(onChange:)` for automatic reload on configuration file changes.
- **Enhanced Documentation** — Decoder contract documentation and async spec usage patterns with examples.
- **YAML/TOML Support Examples** — README examples demonstrating configuration loading from YAML and TOML formats.
- **Code Coverage Reporting** — CI tracking with threshold enforcement for regression detection.
- **Demo App Build in CI** — GitHub Actions job ensuring demo app builds successfully on every commit.
- **Deterministic Error Ordering Golden Tests** — Comprehensive tests with 50+ bindings validating error consistency across runs.
- **Thread-Safety Audit & Tests** — Sanitizer-enabled concurrency tests for binding resolution and provenance reporter access.

### Changed

- Demo app now builds in CI pipeline alongside library tests, ensuring compatibility.
- Improved configuration diffing to include `isSecret` flag for sensitive value redaction.
- Enhanced error diagnostics with spec metadata (description and type names).
- Provenance mapping now supports custom provider-name resolver for flexible provider identification.
- Snapshot stringification is now customizable for bindings and decision fallbacks via stable encoding formats.
- DecisionTrace now carries full decision metadata for improved debugging and decision auditing.

### Fixed

- Snapshot stringification now produces deterministic output across runs.
- Custom provider-name mapping now properly handles structured provenance resolution.
- Thread-safety boundary added to demo context provider (@MainActor).

## [0.1.1] - 2026-01-27

### Fixed

- Failure snapshots now carry diagnostics instead of leaving them empty.
- Provenance reporting supports custom provider-name mapping.
- Snapshot stringification is customizable for bindings and decision fallbacks.
- Config file loader distinguishes invalid JSON from read failures.
- Demo UI wording aligned with wake override behavior.
- Demo context provider state access is now thread-safe.

### Changed

- Clarified `ConfigError` documentation as a stable error surface.

## [0.1.0] - 2025-12-19

### Added

- Wrapper API: Binding, AnyBinding, SpecProfile, ConfigPipeline, diagnostics, snapshots, redaction.
- Demo app (Config Pet) with config loader, manual reload, and error panel.
- Tutorial steps 01-05 covering MVP through optional watching.
- Environment override support and DecisionSpec fallback examples.
- CI workflow and README quickstart.
