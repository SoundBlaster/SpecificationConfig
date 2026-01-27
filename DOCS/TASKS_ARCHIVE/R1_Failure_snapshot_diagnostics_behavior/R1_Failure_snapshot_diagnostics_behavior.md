# R1 — Failure snapshot diagnostics behavior

## Context & Assumptions
- The library promises snapshots that include diagnostics, but current failure snapshots are constructed with empty diagnostics.
- BuildResult already exposes diagnostics separately; the task is to align snapshot behavior and tests with the intended contract.
- This task is sourced from `DOCS/Workplan.md` review follow-ups, not PRD §9.
- Assumption: Including diagnostics in failure snapshots will not break public API expectations beyond test updates.

## Selected Task (ID, Title, source)
- ID: R1
- Title: Failure snapshot diagnostics behavior
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Medium
- Effort: M (estimate)
- Dependencies: None
- Expected outputs: Updated pipeline failure snapshots and tests that reflect the chosen behavior.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Choose behavior: failure snapshots include diagnostics gathered during build.
   - Confirm expected impacts on BuildResult and Snapshot contract.
2. Code update phase
   - Update `ConfigPipeline.build` to pass diagnostics into failure snapshots.
   - Update `ConfigPipeline.buildAsync` similarly.
3. Test update phase
   - Adjust tests that assert failure snapshots have empty diagnostics.
   - Add/adjust assertions to verify snapshot diagnostics mirror failure diagnostics.
4. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Sources/SpecificationConfig/Pipeline.swift` — failure snapshot construction paths.
- `Tests/SpecificationConfigTests/PipelineTests.swift` — failure snapshot expectations.
- Potentially `Tests/SpecificationConfigTests/ConfigLoaderTests.swift` if any failure snapshot expectations exist.

## Affected API Surface (types/functions/modules)
- `ConfigPipeline.build` (behavioral contract for failure snapshots)
- `ConfigPipeline.buildAsync` (behavioral contract for failure snapshots)
- `Snapshot.diagnostics` (semantics on failure)

## Subtasks Checklist (atomic)
- [x] Decide to include diagnostics in failure snapshots (documented in PRD)
- [x] Update failure snapshot construction in `ConfigPipeline.build`
- [x] Update failure snapshot construction in `ConfigPipeline.buildAsync`
- [x] Update relevant tests to reflect new behavior
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- Decision recorded in this PRD and consistent with code changes.
- All failure paths in `ConfigPipeline.build` use the collected `diagnostics` when constructing snapshots.
- All failure paths in `ConfigPipeline.buildAsync` use the collected `diagnostics` when constructing snapshots.
- Tests that previously asserted empty failure snapshot diagnostics are updated to assert presence/consistency.
- CI-equivalent commands pass.

## Verification Commands (repo-accurate, from CI)
```bash
swift build -v
swift test -v
swiftformat --lint .
```

## Definition of Done (aligned with PRD §12)
- Code changes are complete and reviewed locally.
- Tests pass and reflect the updated failure snapshot contract.
- Documentation/comments remain consistent with runtime behavior.
- Workplan entry R1 is marked complete and task PRD is archived.

## Risks & Open Questions
- Risk: External users may have relied on failure snapshots not including diagnostics; change is behavioral but improves consistency.
- Open question: Should a separate flag control whether snapshots carry diagnostics on failure? (Not required for this task.)

**Archived:** 2026-01-27
