# I5 — Performance Metrics in Snapshot

## Context & Assumptions

- Snapshot already captures resolvedValues, decisionTraces, diagnostics
- Pipeline.build() and Pipeline.buildAsync() are the only entry points for snapshot creation
- Swift's ContinuousClock / Duration available on macOS 13+; project targets macOS 15+

## Selected Task

- **ID:** I5
- **Title:** Performance Metrics in Snapshot
- **Source:** DOCS/PRD/IMPROVEMENTS.md §6

## PRD Row Data

- **Priority:** Medium
- **Effort:** S
- **Dependencies:** None
- **Outputs:** PerformanceMetrics struct, updated Snapshot, updated Pipeline

## Implementation Plan

### Phase 1: Define PerformanceMetrics

Create `PerformanceMetrics` struct with binding timing data, decision timing data, spec timing data, and total duration.

### Phase 2: Instrument Pipeline

Add `ContinuousClock` timing around binding application, decision binding evaluation, and spec validation in both `build()` and `buildAsync()`.

### Phase 3: Wire into Snapshot

Add optional `performance` property to Snapshot and pass metrics from Pipeline.

### Phase 4: Tests

Verify timing data is captured and non-zero for all measured phases.

## Files & Change Points

| File | Action |
|------|--------|
| `Sources/SpecificationConfig/Snapshot.swift` | Add `PerformanceMetrics` struct and `performance` property to `Snapshot` |
| `Sources/SpecificationConfig/Pipeline.swift` | Add timing instrumentation in `build()` and `buildAsync()` |
| `Tests/SpecificationConfigTests/PerformanceMetricsTests.swift` | Create tests |

## Subtasks Checklist

- [ ] Define `PerformanceMetrics` struct in Snapshot.swift
- [ ] Add `performance` property to `Snapshot` init
- [ ] Instrument `ConfigPipeline.build()` with timing
- [ ] Instrument `ConfigPipeline.buildAsync()` with timing
- [ ] Add tests for performance metrics capture

## Acceptance Criteria

- PerformanceMetrics contains per-binding, per-decision, per-spec timing and total duration
- Both sync and async pipeline methods produce metrics
- All existing tests pass without changes
- New tests verify timing data is present and reasonable

## Verification Commands

```bash
swift build -v
swift test -v
swiftformat --lint .
```

## Definition of Done

- All tests pass (swift test)
- Build succeeds (swift build)
- Code formatted (swiftformat --lint)

**Archived:** 2026-01-28
