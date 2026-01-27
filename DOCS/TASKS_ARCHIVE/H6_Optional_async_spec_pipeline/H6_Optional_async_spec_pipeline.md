# Task PRD: H6 — Optional async spec pipeline

## Context & Assumptions
- The current pipeline is fully synchronous (`ConfigPipeline.build`) and uses `SpecEntry`/`ContextualSpecEntry` for sync validation.
- SpecificationCore provides `AsyncSpecification` and `AnyAsyncSpecification` for async validations.
- This task adds an opt-in async build path while keeping the synchronous pipeline unchanged.

## Selected Task (ID, Title, source)
- **ID:** H6
- **Title:** Optional async spec pipeline
- **Source:** PRD §9 (Phase H)

## PRD §9 Row Data (priority/effort/deps/outputs)
- **Priority:** Low
- **Effort:** L
- **Inputs:** AnyAsyncSpecification
- **Output:** Async build API + tests
- **Dependencies:** C2
- **Verify:** Unit tests

## Implementation Plan (phased)
1. **Async spec wrappers**
   - Introduce an `AsyncSpecEntry<T>` type mirroring `SpecEntry` but wrapping `AnyAsyncSpecification` with metadata.
2. **Async-aware bindings/profile**
   - Extend `Binding` and `AnyBinding` to accept `asyncValueSpecs` and apply them with async/await.
   - Extend `SpecProfile` to store `asyncFinalSpecs` and expose an async build path.
3. **Async pipeline**
   - Add `ConfigPipeline.buildAsync` that mirrors `build` but awaits async specs for values and final config.
   - Preserve error handling semantics (`collectAll` vs `failFast`).
4. **Tests**
   - Add unit tests that prove async value and async final specs fail as expected and produce diagnostics.

## Files & Change Points (Sources/Tests)
- `Sources/SpecificationConfig/AsyncSpecEntry.swift` (new): async spec wrapper with metadata.
- `Sources/SpecificationConfig/Binding.swift`: add `asyncValueSpecs` to `Binding` initializer.
- `Sources/SpecificationConfig/AnyBinding.swift`: add async apply paths and async spec validation.
- `Sources/SpecificationConfig/SpecProfile.swift`: store `asyncFinalSpecs` and add async build helper.
- `Sources/SpecificationConfig/Pipeline.swift`: add `buildAsync` and async diagnostics wiring.
- `Tests/SpecificationConfigTests/PipelineTests.swift`: add async pipeline tests.

## Affected API Surface (types/functions/modules)
- **New type:** `AsyncSpecEntry<T>`.
- **New API:** `ConfigPipeline.buildAsync(profile:reader:provenanceReporter:errorHandlingMode:)`.
- **Extended APIs:** `Binding` initializer (`asyncValueSpecs`), `SpecProfile` (`asyncFinalSpecs`, optional async build).

## Subtasks Checklist (atomic)
- [x] Add `AsyncSpecEntry<T>` with metadata and async evaluation.
- [x] Extend `Binding`/`AnyBinding` to validate `asyncValueSpecs` with async/await.
- [x] Add `asyncFinalSpecs` support to `SpecProfile`.
- [x] Implement `ConfigPipeline.buildAsync` with async spec evaluation and diagnostics.
- [x] Add unit tests covering async value and final specs.
- [x] Run repo validation commands.
- [x] Update task tracking docs (`next.md`, `Workplan.md`).

## Acceptance Criteria (per subtask)
- `AsyncSpecEntry` mirrors `SpecEntry` behavior and exposes `SpecMetadata` for diagnostics.
- Async value specs are evaluated during binding application in the async pipeline.
- Async final specs are evaluated after finalization in the async pipeline.
- Synchronous pipeline behavior remains unchanged.
- Unit tests validate async failure paths and diagnostics.
- Validation commands pass.

## Verification Commands (repo-accurate, from CI)
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if installed)
- `swift test --sanitize=thread`

## Definition of Done (aligned with PRD §12)
- Async pipeline builds succeed or fail with diagnostics, without breaking the sync path.
- Unit tests cover async spec failures.
- Task tracking reflects completion.

## Risks & Open Questions
- Async spec metadata must remain deterministic; confirm diagnostics include spec description/type.
- Ensure async pipeline does not accidentally run on the main actor.

**Archived:** 2026-01-27
