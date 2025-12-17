# Task PRD — C2: Implement `ConfigPipeline`

**Source:** PRD §9 (Phase C)  
**Priority:** High  
**Effort:** L  
**Dependencies:** B2 (AnyBinding), B3 (Snapshot), B4 (Diagnostics), C1 (SpecProfile)  
**Output:** `Sources/SpecificationConfig/Pipeline.swift` + `Tests/SpecificationConfigTests/PipelineTests.swift`  
**Verify:** `swift build -v`; `swift test -v` (add `swiftformat --lint .` if available)

## Objective & Scope
Create the `ConfigPipeline` that orchestrates applying bindings from a `SpecProfile`, assembling a `Snapshot`, and returning a success/failure result with diagnostics. The pipeline must drive draft population via `AnyBinding`, invoke finalize + final specs from `SpecProfile`, and stop with a failure result when any error occurs (fail-fast by default, aligning with PRD §5.3 until C4 introduces collect-all vs fail-fast modes).

## Constraints & Assumptions
- Use existing types without introducing new dependencies: `AnyBinding`, `Snapshot`, `DiagnosticsReport`, `SpecProfile`, and `Redaction`.
- Preserve binding order during application; diagnostic ordering should leverage current `DiagnosticsReport` determinism (C3 will refine if needed).
- Default behavior treats any diagnostic with severity `.error` as fatal for the build result.
- Pipeline must be unit-testable without UI; provide seams to inject a fake `Configuration.ConfigReader` or test reader.
- Public API requires doc comments for primary types/methods per NFR-5.

## Deliverables
- `ConfigPipeline` type and supporting result enums/structs in `Sources/SpecificationConfig/Pipeline.swift`, exposed via the `SpecificationConfig` module.
- Public API to run the pipeline (e.g., `build(profile:reader:)`) returning success/failure, including the final config, snapshot, and diagnostics.
- Deterministic snapshot assembly capturing resolved values (with redaction) and provenance from bindings/defaults; diagnostics accumulated during binding application, finalize, and final spec execution.
- Unit tests in `Tests/SpecificationConfigTests/PipelineTests.swift` covering success, decode/spec failures, fatal diagnostics behavior, and snapshot contents.

## Plan — Subtasks & Acceptance Criteria
- [ ] **Define pipeline types and result model.**  
  - Acceptance: Add `ConfigPipeline` (or similar) public type plus a `BuildResult` enum (e.g., `.success(final: Snapshot:, config:)`, `.failure(diagnostics:, snapshot:)`) in `Pipeline.swift`. Result carries diagnostics and snapshot in both cases; diagnostics are accessible in stable order via `DiagnosticsReport`.
- [ ] **Implement binding application + draft construction.**  
  - Acceptance: Pipeline applies `SpecProfile` bindings in provided order using a supplied `Configuration.ConfigReader` (or test double), respecting defaults and value specs already encapsulated by `AnyBinding`. On decode/spec failure, append diagnostic and avoid mutating the draft for that key. Successful binding writes draft values and resolved value/provenance entries for the snapshot.
- [ ] **Finalize and run final specs with fatal error handling.**  
  - Acceptance: After bindings, pipeline checks diagnostics; if any errors exist, return failure with snapshot + diagnostics (no finalize). Otherwise, call `SpecProfile.finalize`, then run final specs; on any thrown error or spec failure, add diagnostics and return failure. On success, return finalized config with snapshot populated.
- [ ] **Build snapshot assembly helpers.**  
  - Acceptance: Snapshot includes `ResolvedValue` entries for each successfully applied binding (stringified, provenance, redaction) and accumulated `DiagnosticsReport`. Timestamp is set when snapshot is produced; helper functions keep diagnostics merged from bindings/finalize/final specs.
- [ ] **Add unit tests for pipeline behavior.**  
  - Acceptance: `PipelineTests.swift` covers: (a) happy path producing final config and snapshot values, (b) decode/value spec failure yields failure result with diagnostic and no draft mutation, (c) finalize/final spec failure returns failure with diagnostics, (d) diagnostics remain deterministic with current ordering rules and bindings applied in declared order. Tests run via `swift test -v`.
- [ ] **Document public API.**  
  - Acceptance: DocC comments on pipeline type/result and primary methods describe parameters, behavior, fatal conditions, diagnostics/snapshot contents, and redaction expectations.

## Definition of Done (task-level)
- Pipeline public API exists in `SpecificationConfig` module with doc comments and integrates with existing bindings, diagnostics, snapshot, and spec profile types.
- Build result returns snapshot + diagnostics for both success and failure; default fatal-on-error behavior implemented.
- Unit tests in `PipelineTests.swift` pass and demonstrate reliability, ordering, and failure handling.
- Repository builds and tests cleanly with required commands.

## Verification
- `swift build -v`
- `swift test -v`
- `swiftformat --lint .` (if available)

**Archived:** 2025-12-17
