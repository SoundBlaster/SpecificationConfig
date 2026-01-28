# I13 — Performance Regression Detection

**Status:** Planned
**Priority:** Low
**Phase:** I
**Dependencies:** None

## Problem

No performance benchmarks exist to detect regressions in core operations like pipeline builds, snapshot lookups, and provenance reporting.

## Solution

Add XCTest `measure` blocks for key operations. These provide consistent, repeatable measurements within the test suite and will flag significant deviations as test failures in CI.

### Benchmark Targets

1. **Pipeline.build with 100 bindings** — Measures full pipeline throughput
2. **Pipeline.buildAsync with async decision bindings** — Async pipeline overhead
3. **Snapshot.value(forKey:) lookup** — O(1) dictionary lookup verification
4. **Snapshot.diff(from:)** — Diff computation with large snapshots
5. **ConfigSchema.validate** — Schema validation with many requirements

### Files to Create
- `Tests/SpecificationConfigTests/PerformanceBenchmarkTests.swift`

### Validation
- `swift build` clean
- `swift test` all pass
- `swiftformat --lint .` clean
