# R7 — DemoContextProvider thread safety

## Context & Assumptions
- `DemoContextProvider` is a mutable singleton used by the demo UI and spec wrappers.
- Goal: add a thread-safety boundary to avoid data races without changing behavior.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).
- Assumption: a locking strategy is acceptable if actor isolation would break protocol conformance.

## Selected Task (ID, Title, source)
- ID: R7
- Title: DemoContextProvider thread safety
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Low
- Effort: S (estimate)
- Dependencies: None
- Expected outputs: Thread-safe access to DemoContextProvider state.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Choose locking strategy vs actor isolation; prefer lock to preserve sync protocol usage.
2. Code update phase
   - Add lock and guard all mutable state access within DemoContextProvider.
3. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Demo/ConfigPetApp/ConfigPetApp/DemoContextProvider.swift`

## Affected API Surface (types/functions/modules)
- Demo-only provider; behavior unchanged, only thread-safety added.

## Subtasks Checklist (atomic)
- [x] Decide on locking strategy for thread safety
- [x] Implement lock-protected reads/writes in DemoContextProvider
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- All mutable state access in DemoContextProvider is synchronized.
- No behavior regressions in demo.
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
- Actor isolation could require async usage changes; lock approach avoids API churn.

**Archived:** 2026-01-27
