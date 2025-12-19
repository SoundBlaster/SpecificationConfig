# Task PRD — H2: Add DecisionBinding + DecisionTrace (FirstMatchSpec)

**Source:** PRD §9 (Phase H)  
**Priority:** High  
**Effort:** L  
**Dependencies:** B1, B3, C2  
**Output:** DecisionBinding/DecisionTrace types + pipeline integration + demo update + unit tests  
**Verify:** `swift build -v`; `swift test -v` (add `swiftformat --lint .` if available)

## Objective & Scope
Introduce DecisionBinding and DecisionTrace so applications can declare DecisionSpec-based fallbacks that are applied
by the pipeline when a value is missing. Capture which decision matched in the Snapshot for debugging/UI use.

Additionally, provide basic-case convenience APIs in SpecificationConfig so the demo app can use fallbacks and
value specs without importing SpecificationCore directly.

## Constraints & Assumptions
- Keep deterministic ordering of diagnostics and snapshot entries (C3 behavior).
- No new external dependencies; use SpecificationCore internally only.
- Maintain backwards-compatible behavior for existing bindings and pipeline defaults.
- Use ASCII-only content in new docs/comments.

## Deliverables
- `DecisionBinding` type with ordered decision entries and a target key path.
- `DecisionTrace` model recorded in `Snapshot` for matched decision (index + display name).
- Pipeline update to apply decision bindings after normal bindings.
- Convenience decision/spec wrappers so the demo app can avoid `import SpecificationCore` for basic predicates.
- Demo app updated to use the new APIs and drop direct SpecificationCore usage.
- Unit tests for decision fallback behavior and trace capture.

## Plan — Subtasks & Acceptance Criteria
- [x] **Define DecisionTrace and DecisionEntry helpers.**
  - Add `DecisionTrace` model (key, matched index, display name/type).
  - Add `DecisionEntry` (or similar) that accepts a predicate + result (and optional description) without requiring
    SpecificationCore in app code.
  - Acceptance: DecisionEntry can be created with a closure and yields stable metadata for diagnostics/snapshot.
- [x] **Add DecisionBinding API and SpecProfile support.**
  - Create `DecisionBinding<Draft, Value>` with `key`, `keyPath`, and ordered decision entries.
  - Extend `SpecProfile` to accept `decisionBindings` (default empty) without breaking existing call sites.
  - Acceptance: Profile can declare decision bindings alongside normal bindings.
- [x] **Integrate DecisionBinding into the pipeline + Snapshot.**
  - Apply decision bindings after normal bindings if the target value is still nil.
  - Record matched decision metadata in `Snapshot` (new `decisionTraces` array) and add lookup helper.
  - Emit diagnostics when no decision matches.
  - Acceptance: Missing values can be derived via decisions and snapshot includes the trace.
- [x] **Add basic spec convenience for value specs.**
  - Provide a `SpecEntry` initializer that takes a description + predicate closure so apps can avoid
    `PredicateSpec` usage in basic cases.
  - Acceptance: Demo can define value specs without `import SpecificationCore`.
- [x] **Update demo app and tests.**
  - Remove `import SpecificationCore` from `Demo/ConfigPetApp/ConfigPetApp/AppConfig.swift`.
  - Replace DecisionSpec fallback and value specs with new convenience APIs.
  - Add/adjust unit tests in `Tests/SpecificationConfigTests` for decision fallback + trace capture.

## Definition of Done (task-level)
- DecisionBinding applies fallbacks in the pipeline and records DecisionTrace in Snapshot.
- Demo app uses SpecificationConfig-only APIs for basic specs/fallbacks.
- All tests pass (`swift build -v`, `swift test -v`).

## Verification
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if available)
