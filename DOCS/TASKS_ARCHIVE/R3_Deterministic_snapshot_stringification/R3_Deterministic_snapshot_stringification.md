# R3 — Deterministic snapshot stringification

## Context & Assumptions
- Snapshot values are currently stringified with `String(describing:)`, which can be nondeterministic for unordered types.
- Goal: provide a deterministic stringification hook for bound values and decision fallbacks without breaking existing API behavior.
- This task is sourced from review follow-ups in `DOCS/Workplan.md` (not PRD §9).
- Assumption: adding optional `stringify` parameters with defaults is an acceptable API extension.

## Selected Task (ID, Title, source)
- ID: R3
- Title: Deterministic snapshot stringification
- Source: `DOCS/Workplan.md`

## PRD §9 Row Data (priority/effort/deps/outputs)
- Priority: Medium
- Effort: M (estimate)
- Dependencies: None
- Expected outputs: Binding/DecisionBinding stringification hook and tests covering custom stringifier usage.
- PRD §9 row: N/A (review follow-up task)

## Implementation Plan (phased)
1. Decision phase
   - Choose hook strategy: add `stringify` closure to `Binding` and `DecisionBinding` with defaults.
2. Code update phase
   - Add `stringify` stored property + initializer parameter to `Binding`.
   - Update `AnyBinding` to use `binding.stringify` when capturing snapshot values.
   - Add `stringify` stored property + initializer parameter to `DecisionBinding`.
   - Update `DecisionBinding.apply` to use the custom stringifier for trace values.
3. Test update phase
   - Add tests that assert snapshot values use custom stringifier for bindings and decision fallbacks.
4. Validation phase
   - Run CI-equivalent commands and ensure tests pass.

## Files & Change Points (Sources/Tests)
- `Sources/SpecificationConfig/Binding.swift`
- `Sources/SpecificationConfig/AnyBinding.swift`
- `Sources/SpecificationConfig/DecisionBinding.swift`
- `Tests/SpecificationConfigTests/PipelineTests.swift`

## Affected API Surface (types/functions/modules)
- `Binding` (new optional `stringify` parameter)
- `DecisionBinding` (new optional `stringify` parameter)
- `AnyBinding.applyAndCapture*` (stringify behavior)

## Subtasks Checklist (atomic)
- [x] Decide on `stringify` closures with defaults
- [x] Add `stringify` to `Binding` and wire into `AnyBinding` capture
- [x] Add `stringify` to `DecisionBinding` and wire into decision capture
- [x] Add tests for custom stringifier behavior
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .` (if available)

## Acceptance Criteria (per subtask)
- `Binding` and `DecisionBinding` accept custom stringifiers without breaking existing call sites.
- Snapshot values reflect custom stringification when provided.
- Tests validate both binding and decision stringification.
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
- Risk: API surface expansion may require additional documentation in DocC; defer to docs team if needed.
- Open question: Should there be a shared stringifier protocol for complex types? Not required for this task.

**Archived:** 2026-01-27
