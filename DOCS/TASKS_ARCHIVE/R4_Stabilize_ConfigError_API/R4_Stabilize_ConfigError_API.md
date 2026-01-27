# R4 — Stabilize ConfigError API

## Context & Assumptions
- `ConfigError` is a public error type used by bindings and profiles.
- It currently carries a “temporary” marker comment, which is inconsistent with actual usage and tests.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).
- Assumption: keeping `ConfigError` public is the least disruptive option and aligns with existing test usage.

## Selected Task (ID, Title, source)
- ID: R4
- Title: Stabilize ConfigError API
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Medium
- Effort: S (estimate)
- Dependencies: None
- Expected outputs: `ConfigError` documentation updated to remove “temporary” status and describe intended use.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Choose stabilization approach: retain public `ConfigError` and remove temporary marker.
2. Code update phase
   - Update documentation comment to describe stable usage.
3. Validation phase
   - Run CI-equivalent commands to ensure no regressions.

## Files & Change Points (Sources/Tests)
- `Sources/SpecificationConfig/AnyBinding.swift` — `ConfigError` doc comment.

## Affected API Surface (types/functions/modules)
- `ConfigError` (documentation-only change, public API remains intact)

## Subtasks Checklist (atomic)
- [x] Decide to keep `ConfigError` public and remove temporary marker
- [x] Update `ConfigError` documentation comment
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- `ConfigError` no longer labeled as temporary.
- Documentation clearly states its purpose and where it is surfaced.
- CI-equivalent commands pass.

## Verification Commands (repo-accurate, from CI)
```bash
swift build -v
swift test -v
swiftformat --lint .
```

## Definition of Done (aligned with PRD §12)
- Code changes complete and reviewed locally.
- Tests pass.
- Task marked complete in `DOCS/Workplan.md` and archived from `DOCS/INPROGRESS`.

## Risks & Open Questions
- None; this is documentation-only and reduces ambiguity.

**Archived:** 2026-01-27
