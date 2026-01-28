# I13 — Performance Regression Detection

**Status:** Completed
**Archived:** 2026-01-28

## Summary

Added 5 performance benchmark tests covering core operations. Uses XCTest `measure` blocks for consistent, repeatable measurements and a `ContinuousClock`-based benchmark for async operations.

## Changes

### New Files
- `Tests/SpecificationConfigTests/PerformanceBenchmarkTests.swift` — 5 benchmark tests

### Benchmarks
1. **Pipeline.build with 100 bindings** — ~0.4ms average (XCTest measure)
2. **Pipeline.buildAsync with async decisions** — <10ms per iteration verified (ContinuousClock)
3. **Snapshot.value(forKey:) with 500 keys** — ~0.12ms for 500 lookups (XCTest measure)
4. **Snapshot.diff(from:) with 200 keys** — ~0.5ms average (XCTest measure)
5. **ConfigSchema.validate with 200 requirements** — ~0.6ms average (XCTest measure)

### Design Decisions
- **XCTest `measure` for sync tests**: Provides built-in regression detection with standard deviation tracking.
- **ContinuousClock for async test**: `measure` blocks don't support `async` closures; used manual timing with assertion instead.
- **No CI threshold enforcement**: XCTest measure blocks report but don't fail without baselines. Performance regressions will be visible in CI output.

## Validation
- 172 tests passing
- swiftformat lint clean
- swift build clean
