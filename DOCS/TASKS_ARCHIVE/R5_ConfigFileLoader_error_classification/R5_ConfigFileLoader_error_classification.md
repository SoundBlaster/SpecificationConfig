# R5 — ConfigFileLoader error classification

## Context & Assumptions
- `ConfigFileLoader` currently treats any `NSCocoaErrorDomain` error as invalid JSON, which mislabels file I/O failures.
- Goal: only classify JSON parsing errors as invalid JSON; other I/O failures should map to a more appropriate error case.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).

## Selected Task (ID, Title, source)
- ID: R5
- Title: ConfigFileLoader error classification
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Low
- Effort: S (estimate)
- Dependencies: None
- Expected outputs: Correct error mapping for JSON parse vs file I/O errors, with tests if applicable.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Determine which error cases correspond to JSON parsing vs other I/O errors.
2. Code update phase
   - Adjust `ConfigFileLoader.createReader` error handling to distinguish parsing from read errors.
3. Test update phase (if feasible)
   - Add or update tests to cover invalid JSON and read failures.
4. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Demo/ConfigPetApp/ConfigPetApp/ConfigFileLoader.swift`
- `Demo/ConfigPetApp/ConfigPetAppTests/ConfigPetAppTests.swift` (if tests added)

## Affected API Surface (types/functions/modules)
- `ConfigFileLoader.LoadError` (behavioral mapping, API unchanged)

## Subtasks Checklist (atomic)
- [x] Decide on error mapping for JSON parse vs file I/O
- [x] Update `ConfigFileLoader` error handling
- [x] Add/adjust tests (if applicable)
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- Invalid JSON errors are only used when JSON parsing fails.
- File read errors are classified as read/creation failures, not JSON invalidation.
- Tests cover error mapping where possible.
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
- Determining specific error codes for JSON parsing may require Foundation error inspection. If uncertain, keep logic minimal and safe.

**Archived:** 2026-01-27
