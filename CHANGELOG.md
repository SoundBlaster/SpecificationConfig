# Changelog

All notable changes to this project will be documented in this file.

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
