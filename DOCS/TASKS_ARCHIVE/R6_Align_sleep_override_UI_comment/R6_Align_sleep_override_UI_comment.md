# R6 — Align sleep override UI/comment

## Context & Assumptions
- The demo button currently wakes the pet (`sleepOverride = false`) but a comment implies sleeping.
- Goal: align UI/wording with actual behavior without changing functional logic.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).

## Selected Task (ID, Title, source)
- ID: R6
- Title: Align sleep override UI/comment
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Low
- Effort: S (estimate)
- Dependencies: None
- Expected outputs: Updated demo UI/comment text to match wake override behavior.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Keep behavior as “wake up” and adjust comments/text accordingly.
2. Code update phase
   - Update `ConfigManager` comment.
   - Update UI text describing the override (if needed).
3. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Demo/ConfigPetApp/ConfigPetApp/ConfigManager.swift`
- `Demo/ConfigPetApp/ConfigPetApp/ContentView.swift`

## Affected API Surface (types/functions/modules)
- Demo UI and comments only (no API behavior change).

## Subtasks Checklist (atomic)
- [x] Decide to keep wake behavior and update wording
- [x] Update comment and UI text
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- Wording reflects wake override behavior.
- Demo UI no longer suggests sleeping when the action wakes the pet.
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
- None.

**Archived:** 2026-01-27
