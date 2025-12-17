# Task PRD — C1: Implement `SpecProfile<Draft, Final>`

**Source:** PRD §9 (Phase C)  
**Priority:** High  
**Effort:** M  
**Dependencies:** B1 (Binding API)  
**Output:** `Sources/SpecificationConfig/SpecProfile.swift` + unit tests  
**Verify:** `swift build -v`; `swift test -v` (add `swiftformat --lint .` if available)

## Objective & Scope
Implement the `SpecProfile<Draft, Final>` type that aggregates bindings, drives draft-to-final conversion, and exposes validation hooks needed by the upcoming `ConfigPipeline` (C2). Scope covers the core data model, initializer(s), and helper methods to:
- Hold an ordered list of bindings (`[AnyBinding<Draft>]`).
- Apply bindings to a draft using a `ConfigReader` and run value specs embedded in bindings.
- Finalize the draft into a strongly-typed `Final` value.
- Optionally run post-finalization specs on the `Final` value.

## Constraints & Assumptions
- Use existing types from B1/B2: `Binding`, `AnyBinding`, and `ConfigError` placeholder diagnostics. Full diagnostics will be upgraded in B4.
- Keep APIs in the `SpecificationConfig` module and avoid adding new external dependencies.
- Preserve deterministic binding order as provided; no implicit sorting (C3 will address deterministic diagnostics ordering in pipeline).
- Public API must include doc comments for main types/functions (NFR-5).

## Deliverables
- Public `SpecProfile<Draft, Final>` type in `Sources/SpecificationConfig/SpecProfile.swift` with documented API.
- Unit tests under `Tests/SpecificationConfigTests/SpecProfileTests.swift` covering success/failure paths and spec enforcement.
- Updated module exports if needed so the new type is visible to library consumers.

## Plan — Subtasks & Acceptance Criteria
- [ ] **Define `SpecProfile` data model and initializer(s).**
  - Acceptance: Struct or class holding `bindings: [AnyBinding<Draft>]`, `finalize: (Draft) throws -> Final`, and optional `finalSpecs: [AnySpecification<Final>]` (or equivalent). Provides at least one public initializer that sets these properties; ensures bindings are kept in declared order.
- [ ] **Implement binding application + finalize helpers.**
  - Acceptance: Public method(s) to construct a `Draft`, apply bindings using a supplied `Configuration.ConfigReader`, and return a populated draft while propagating decode/spec errors (using existing `ConfigError` until B4). Another method runs finalize on a provided draft and then executes `finalSpecs`, failing fast on spec violations.
- [ ] **Expose convenience API for pipeline integration.**
  - Acceptance: Provide a top-level helper (e.g., `build(reader:)` or similar) that performs “apply bindings → finalize → post-specs” in sequence and returns the final config, enabling C2 to orchestrate without duplicating logic. Method should be generic-friendly and keep draft mutation encapsulated.
- [ ] **Add unit tests.**
  - Acceptance: Tests create minimal `Draft`/`Final` structs, define bindings with value specs, and verify: (a) successful application produces expected `Final`, (b) missing/invalid values surface errors, (c) post-final specs are enforced, (d) bindings are applied in declared order when multiple keys exist. Tests live in `SpecProfileTests.swift` and compile/run via `swift test -v`.
- [ ] **Document public API.**
  - Acceptance: DocC-style comments for `SpecProfile` and its primary methods covering purpose, parameters, thrown errors, and usage notes; align with terminology in PRD §4.

## Definition of Done (task-level)
- `SpecProfile` API compiled and exported from the `SpecificationConfig` module with doc comments.
- Happy path and failure path unit tests pass (`swift test -v`).
- Behavior aligns with PRD §12 expectations for reliable, testable core pipeline pieces (unit-testable without UI; no silent partial application).

## Verification
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if available)
