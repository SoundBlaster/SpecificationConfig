# Task PRD — H3: Add context provider support for specs

**Source:** PRD §9 (Phase H)  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** C1  
**Output:** SpecProfile accepts AnyContextProvider + contextual specs evaluated in pipeline  
**Verify:** `swift build -v`; `swift test -v` (add `swiftformat --lint .` if available)

## Objective & Scope
Enable context-aware specifications by letting a `SpecProfile` carry a `ContextProviding` source and applying
context-dependent specs during binding and final validation. This should support `SpecificationCore`'s
`ContextProviding.predicate/specification` patterns without requiring manual context threading at call sites.

In scope:
- Add `AnyContextProvider` support to `SpecProfile`.
- Add context-aware spec entries for value specs and final specs.
- Evaluate contextual specs in `AnyBinding` and `SpecProfile`/`ConfigPipeline` flows.
- Unit tests covering success and missing-context failure paths.

Out of scope:
- Demo updates (handled by H4).
- Async context evaluation (handled by H6).
- Property-wrapper derived state (handled by H5).

## Constraints & Assumptions
- Preserve existing API behavior for non-context specs.
- No new external dependencies.
- Keep deterministic diagnostics ordering.
- ASCII-only content.

## Deliverables
- `ContextualSpecEntry` (or equivalent) to evaluate `(EvaluationContext, T) -> Bool` predicates.
- `SpecProfile` carries an optional `AnyContextProvider<EvaluationContext>`.
- `Binding` accepts contextual value specs (default empty).
- Pipeline uses context provider to evaluate contextual specs and reports failures.
- Unit tests for contextual value spec and contextual final spec; missing-provider failure is surfaced.

## Functional Requirements
1. Profiles can supply a context provider for spec evaluation.
2. Contextual value specs run during binding when a provider is present.
3. Contextual final specs run after finalization when a provider is present.
4. Missing context provider yields a deterministic diagnostic error.

## Non-Functional Requirements
- No regressions in binding ordering or diagnostics determinism.
- No changes to existing binding/spec call sites unless adding new optional parameters.
- Tests do not depend on UI or demo app.

## Edge Cases & Failure Scenarios
- Contextual specs declared but context provider is nil.
- Contextual spec fails while standard value specs pass.
- Contextual final spec fails after successful binding.

## Plan — Subtasks & Acceptance Criteria
- [x] **Define context-aware spec entry type.**
  - Add `ContextualSpecEntry<T>` (or similar) that stores metadata and a predicate taking
    `(EvaluationContext, T)`.
  - Provide initializer(s) for description + predicate.
  - Acceptance: A contextual spec can be declared without importing SpecificationCore in app code.

- [x] **Extend Binding and SpecProfile to accept contextual specs.**
  - Add `contextualValueSpecs: [ContextualSpecEntry<Value>] = []` to `Binding`.
  - Add `contextProvider: AnyContextProvider<EvaluationContext>?` and
    `contextualFinalSpecs: [ContextualSpecEntry<Final>] = []` to `SpecProfile`.
  - Acceptance: Existing call sites compile unchanged (new params defaulted).

- [x] **Evaluate contextual specs during pipeline execution.**
  - Update `AnyBinding.apply` / `applyAndCapture` to accept optional context provider and
    evaluate contextual value specs when present.
  - Update `SpecProfile.finalizeDraft` (or equivalent) to evaluate contextual final specs.
  - Introduce a new `ConfigError` for missing context provider and map it to diagnostics.
  - Acceptance: Contextual spec failures are reported with spec metadata; missing provider
    surfaces as a diagnostic error.

- [x] **Unit tests.**
  - Add test that contextual value spec passes with `StaticContextProvider(EvaluationContext)`.
  - Add test that contextual final spec fails and yields diagnostic context.
  - Add test for missing context provider when contextual specs exist.

## Definition of Done
- Context provider support is available in `SpecProfile`.
- Contextual specs run in pipeline with deterministic diagnostics.
- Unit tests cover success and failure scenarios.
- `swift build -v` and `swift test -v` pass.

## Verification
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if available)
