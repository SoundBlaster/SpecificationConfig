# Task PRD — H1: Add spec metadata to diagnostics (description/type name)

**Source:** PRD §9 (Phase H)  
**Priority:** High  
**Effort:** M  
**Dependencies:** B4, C2  
**Output:** `Sources/SpecificationConfig/SpecMetadata.swift` + diagnostics updates + unit tests  
**Verify:** `swift build -v`; `swift test -v` (add `swiftformat --lint .` if available)

## Objective & Scope
Add spec metadata support so diagnostics can surface a human-readable spec description (or type name fallback) when
value or final specs fail. This reduces ambiguity in UI error panels and makes debugging configuration rules easier.

Scope covers:
- A `SpecMetadata` representation in `SpecificationConfig`.
- Binding/spec storage updates to carry metadata to the pipeline.
- Diagnostic emission that includes spec description/type name in context.
- Tests that assert metadata is present and deterministic.

## Constraints & Assumptions
- Do not modify SpecificationCore; wrap metadata in `SpecificationConfig` types.
- Maintain deterministic diagnostics ordering (C3 behavior).
- Keep public API backward-compatible where possible; if changes are needed, provide overloads.
- No new dependencies; stay within `Sources/SpecificationConfig` and `Tests/SpecificationConfigTests`.
- Use ASCII-only content for new docs and code comments.

## Deliverables
- `SpecMetadata` type that can be constructed from a `Specification` and optional description.
- Binding/AnyBinding support for passing metadata through spec evaluation.
- Diagnostics include a stable spec label (description or type name) in `DiagnosticItem.context`.
- Unit tests covering:
  - Description from `PredicateSpec(description:)` is surfaced.
  - Type name fallback is used when no description is available.
  - Deterministic ordering unaffected by metadata.

## Plan — Subtasks & Acceptance Criteria
- [x] **Define spec metadata model and helpers.**
  - Add `SpecMetadata` (and any needed helper wrappers) in `Sources/SpecificationConfig/SpecMetadata.swift`.
  - Acceptance: Can create metadata from a concrete `Specification` with an optional description; exposes a stable
    `displayName` (description first, type name fallback).
- [x] **Propagate metadata through bindings.**
  - Update `Binding` to carry spec metadata alongside `AnySpecification` instances (add overloads if needed).
  - Update `AnyBinding` to iterate metadata entries and surface metadata on failures.
  - Acceptance: On spec failure, the thrown error includes spec metadata, not just the key.
- [x] **Emit diagnostics with spec metadata.**
  - Update `ConfigError` and `ConfigPipeline.diagnosticFromConfigError` (or equivalent) to include spec metadata in
    `DiagnosticItem.context` (e.g., `spec`, `specType`).
  - Acceptance: Diagnostics include the spec description/type name for both value and final spec failures.
- [x] **Update tests.**
  - Add/adjust tests in `Tests/SpecificationConfigTests` (likely `PipelineTests` or `BindingTests`).
  - Acceptance: Tests assert that diagnostics include `spec` context with the expected description or type name.

## Definition of Done (task-level)
- Spec failures produce diagnostics with spec description/type name in context.
- Existing pipeline behavior and deterministic ordering remain intact.
- `swift build -v` and `swift test -v` pass locally.

## Verification
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if available)

**Archived:** 2025-12-19
