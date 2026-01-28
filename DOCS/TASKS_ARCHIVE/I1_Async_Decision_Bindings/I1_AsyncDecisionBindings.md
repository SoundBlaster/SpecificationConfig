# I1 — Async Decision Bindings

## Context & Assumptions

`DecisionBinding` currently supports only synchronous predicates via `(Context) -> Result?`. Production environments require async decisions for database lookups, API calls, and remote feature flag evaluation. The existing codebase already has async patterns for value specs (`AsyncSpecEntry`, `AnyBinding.applyAsync`, `Pipeline.buildAsync`) that serve as templates.

SpecificationCore does **not** provide an `AsyncDecisionSpec` protocol. This implementation stays within SpecificationConfig, using async closures (mirroring how `DecisionEntry` uses sync closures without requiring a SpecificationCore protocol).

**Assumptions:**
- Async decision entries are only evaluated via `buildAsync`; the sync `build` method does not change.
- `SpecProfile` gains a new `asyncDecisionBindings` parameter with an empty default.
- Async decisions are evaluated sequentially (same ordering guarantee as sync decisions).
- The existing `DecisionResolution` enum is reused.

## Selected Task

- **ID:** I1
- **Title:** Async Decision Bindings
- **Source:** DOCS/PRD/IMPROVEMENTS.md §2

## PRD Row Data

- **Priority:** Critical
- **Effort:** M (medium)
- **Dependencies:** None
- **Outputs:** New types, extended SpecProfile/Pipeline, tests

## Implementation Plan

### Phase 1 — AsyncDecisionEntry and AsyncDecisionBinding types

Create `AsyncDecisionEntry<Context, Result>` and `AsyncDecisionBinding<Draft, Value>` mirroring the sync counterparts.

### Phase 2 — AnyAsyncDecisionBinding type erasure

Create `AnyAsyncDecisionBinding<Draft>` that type-erases `AsyncDecisionBinding`.

### Phase 3 — SpecProfile integration

Add `asyncDecisionBindings: [AnyAsyncDecisionBinding<Draft>]` parameter to `SpecProfile.init`.

### Phase 4 — Pipeline.buildAsync integration

Update `Pipeline.buildAsync` to evaluate `asyncDecisionBindings` after sync decision bindings.

### Phase 5 — Tests

Add comprehensive tests covering match, no-match, skip, and error scenarios.

## Files & Change Points

| File | Action | Description |
|------|--------|-------------|
| `Sources/SpecificationConfig/AsyncDecisionBinding.swift` | **Create** | `AsyncDecisionEntry`, `AsyncDecisionBinding`, `AnyAsyncDecisionBinding` |
| `Sources/SpecificationConfig/SpecProfile.swift` | **Modify** | Add `asyncDecisionBindings` property and init parameter |
| `Sources/SpecificationConfig/Pipeline.swift` | **Modify** | Evaluate async decision bindings in `buildAsync` |
| `Sources/SpecificationConfig/AnyBinding.swift` | **Check** | Verify `ConfigError` has needed cases (add `asyncDecisionFallbackFailed` if needed) |
| `Tests/SpecificationConfigTests/AsyncDecisionBindingTests.swift` | **Create** | Tests for async decision bindings |

## Affected API Surface

| Type/Function | Module | Change |
|---------------|--------|--------|
| `AsyncDecisionEntry<Context, Result>` | SpecificationConfig | New public struct |
| `AsyncDecisionBinding<Draft, Value>` | SpecificationConfig | New public struct |
| `AnyAsyncDecisionBinding<Draft>` | SpecificationConfig | New public struct |
| `SpecProfile.init(...)` | SpecificationConfig | New `asyncDecisionBindings` parameter (defaulted) |
| `SpecProfile.asyncDecisionBindings` | SpecificationConfig | New public property |
| `ConfigPipeline.buildAsync(...)` | SpecificationConfig | Evaluates async decision bindings |

## Subtasks Checklist

- [x] **S1:** Create `AsyncDecisionEntry<Context, Result>` with async `decide` closure, metadata, and `resolve` method
- [x] **S2:** Create `AsyncDecisionBinding<Draft, Value>` with async `applyAsync(to:)` returning `DecisionResolution`
- [x] **S3:** Create `AnyAsyncDecisionBinding<Draft>` type-erased wrapper
- [x] **S4:** Add `asyncDecisionBindings` property and init parameter to `SpecProfile`
- [x] **S5:** Update `Pipeline.buildAsync` to iterate `asyncDecisionBindings` after sync decision bindings
- [x] **S6:** Add `ConfigError.asyncDecisionFallbackFailed(key:)` case and pipeline diagnostic mapping
- [x] **S7:** Write test: async decision entry matches and resolves value
- [x] **S8:** Write test: async decision binding applies first match and records trace
- [x] **S9:** Write test: async decision binding no-match produces diagnostic
- [x] **S10:** Write test: async decision binding skips when draft field already set
- [x] **S11:** Write test: async decision binding works through full pipeline buildAsync
- [x] **S12:** Run `swift build -v` and `swift test -v` to validate

## Acceptance Criteria

| Subtask | Acceptance Criteria |
|---------|---------------------|
| S1 | `AsyncDecisionEntry` has `init(description:decide:)`, `init(description:predicate:result:)`, and `resolve(_:) async -> Result?` |
| S2 | `AsyncDecisionBinding` has `key`, `keyPath`, `decisions`, `stringify`, `isSecret`; `applyAsync(to:)` returns `DecisionResolution` |
| S3 | `AnyAsyncDecisionBinding` erases `Value` generic; exposes `key`, `isSecret`, async `applyAsync(to:)` |
| S4 | `SpecProfile.init` accepts `asyncDecisionBindings` defaulting to `[]`; property is public |
| S5 | `buildAsync` evaluates async decision bindings, records traces and resolved values, handles noMatch |
| S6 | `ConfigError` has `asyncDecisionFallbackFailed(key:)` case; pipeline maps it to `DiagnosticItem` |
| S7-S11 | Each test scenario passes; assertions match sync decision binding test patterns |
| S12 | `swift build -v` succeeds; `swift test -v` passes all tests including new ones |

## Verification Commands

```bash
swift build -v
swift test -v
swift test --filter AsyncDecisionBinding
```

## Definition of Done

- All subtasks S1-S12 are checked off.
- `swift build -v` succeeds with no warnings in SpecificationConfig target.
- `swift test -v` passes all existing and new tests.
- New public API follows the same patterns as existing sync `DecisionBinding` and async `AnyBinding`.
- No changes to the sync `build` method or existing sync decision binding behavior.

## Risks & Open Questions

| Risk | Mitigation |
|------|------------|
| SpecificationCore may add `AsyncDecisionSpec` in future | Design `AsyncDecisionEntry` init to accept a protocol-based spec if one exists later, but closure-first for now |
| Async decisions may throw errors beyond noMatch | Reuse the same `try/catch` pattern from `AnyBinding.applyAsync`; wrap errors in diagnostics |
| Pipeline ordering: async after sync decisions | Document that async decisions run after sync decisions, both after regular bindings |

**Archived:** 2026-01-27
