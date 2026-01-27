# R2 — Provenance mapping resolver

## Context & Assumptions
- Provenance tracking currently parses provider name strings inside `ResolvedValueProvenanceReporter`, which is brittle.
- The goal is to make provenance mapping configurable without breaking existing defaults.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).
- Assumption: Adding an initializer with a resolver closure is acceptable API expansion.

## Selected Task (ID, Title, source)
- ID: R2
- Title: Provenance mapping resolver
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Medium
- Effort: M (estimate)
- Dependencies: None
- Expected outputs: Customizable provenance mapping in `ResolvedValueProvenanceReporter` plus tests for custom provider names.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Choose implementation strategy: add injectable resolver closure with default mapping to preserve current behavior.
2. Code update phase
   - Add stored resolver and init to `ResolvedValueProvenanceReporter`.
   - Route provenance derivation through the resolver.
3. Test update phase
   - Add test validating custom resolver mapping for a provider name.
   - Keep existing provenance tests passing.
4. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Sources/SpecificationConfig/ProvenanceReporter.swift` — add resolver and use it.
- `Tests/SpecificationConfigTests/PipelineTests.swift` — add custom resolver test or add new test file.

## Affected API Surface (types/functions/modules)
- `ResolvedValueProvenanceReporter` (new initializer and behavior hook)

## Subtasks Checklist (atomic)
- [x] Decide on injectable resolver with default mapping
- [x] Implement resolver storage + initializer
- [x] Update provenance derivation to use resolver
- [x] Add/adjust tests for custom provider name mapping
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- Resolver is configurable while preserving current default behavior.
- Provenance mapping no longer depends solely on internal string parsing.
- Custom resolver test passes and demonstrates override behavior.
- CI-equivalent commands pass.

## Verification Commands (repo-accurate, from CI)
```bash
swift build -v
swift test -v
swiftformat --lint .
```

## Definition of Done (aligned with PRD §12)
- Code changes are complete and reviewed locally.
- Tests updated and passing.
- Task is marked complete in `DOCS/Workplan.md` and archived from `DOCS/INPROGRESS`.

## Risks & Open Questions
- Risk: External users may want access to provider metadata beyond name strings. Resolver gives an escape hatch but does not change upstream provider APIs.
- Open question: Should the resolver expose more structured inputs in the future (e.g., provider type)? Not required for this task.

**Archived:** 2026-01-27
