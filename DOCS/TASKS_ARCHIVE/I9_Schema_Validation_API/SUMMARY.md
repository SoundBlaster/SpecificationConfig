# I9 — Schema Validation API

**Status:** Completed
**Archived:** 2026-01-28

## Summary

Added `ConfigSchema` to validate required keys before binding. Allows declaring required/optional keys with typed checks and validating their presence in the configuration provider upfront.

## Changes

### New Files
- `Sources/SpecificationConfig/ConfigSchema.swift` — `ConfigSchema` struct with `KeyCheck`, `KeyRequirement`, and `validate(reader:)` method
- `Tests/SpecificationConfigTests/ConfigSchemaTests.swift` — 7 tests covering required/optional keys, type checks, and error reporting

### Design Decisions
- **Typed `KeyCheck`**: Instead of a single `reader.string()` check for all types, introduced `KeyCheck` struct with `.string`, `.int`, `.bool`, `.double` static members and `.custom()` factory. This ensures integer keys aren't falsely reported as missing when checked with `reader.string()`.
- **`KeyRequirement` factory methods**: Used `.required()` and `.optional()` static methods for ergonomic schema declaration.
- **Reuses `DiagnosticsReport`**: Validation results use the existing `DiagnosticsReport` type for consistency with the rest of the pipeline.
- **`Sendable` conformance**: Both `ConfigSchema` and its nested types conform to `Sendable` for Swift 6 compatibility.

## Validation
- 161 tests passing
- swiftformat lint clean
- swift build clean
