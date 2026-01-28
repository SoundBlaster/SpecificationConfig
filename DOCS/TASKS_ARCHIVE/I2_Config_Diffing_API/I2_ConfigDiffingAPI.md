# I2 — Config Diffing API for Reloads

## Context & Assumptions

When configurations reload, consumers have no way to know what changed between snapshots. This makes it hard to show change notifications, highlight modified fields in UI, or log configuration drift. The Snapshot type already has `resolvedValues: [ResolvedValue]` with key/stringifiedValue pairs, making diffing straightforward.

**Assumptions:**
- Diff compares resolved values by key, using `stringifiedValue` for equality.
- Secret values are compared by their raw `stringifiedValue`, not `displayValue`.
- Provenance changes are tracked as modifications.
- The diff result is a simple struct, not a full change-tracking system.

## Selected Task

- **ID:** I2
- **Title:** Config Diffing API for Reloads
- **Source:** DOCS/PRD/IMPROVEMENTS.md §3

## PRD Row Data

- **Priority:** High
- **Effort:** S (small)
- **Dependencies:** None
- **Outputs:** `ConfigDiff` struct, `Snapshot.diff(from:)` method, tests

## Files & Change Points

| File | Action | Description |
|------|--------|-------------|
| `Sources/SpecificationConfig/Snapshot.swift` | **Modify** | Add `ConfigDiff` struct and `Snapshot.diff(from:)` |
| `Tests/SpecificationConfigTests/SnapshotTests.swift` | **Modify** | Add diff tests |

## Subtasks Checklist

- [x] **S1:** Define `ConfigDiff` struct with added, removed, modified
- [x] **S2:** Implement `Snapshot.diff(from:)` method
- [x] **S3:** Write test: diff detects added keys
- [x] **S4:** Write test: diff detects removed keys
- [x] **S5:** Write test: diff detects modified values
- [x] **S6:** Write test: diff with identical snapshots returns empty
- [x] **S7:** Write test: diff detects provenance changes
- [x] **S8:** Run `swift build -v` and `swift test -v` to validate

## Verification Commands

```bash
swift build -v
swift test -v
swift test --filter SnapshotTests
```

**Archived:** 2026-01-27
