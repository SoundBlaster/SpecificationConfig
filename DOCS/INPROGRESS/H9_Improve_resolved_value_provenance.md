# Task PRD — H9: Improve resolved value provenance

**Source:** PRD §9 (Phase H)  
**Priority:** High  
**Effort:** M  
**Dependencies:** D2, C2  
**Output:** Resolved values capture provider/source metadata (file/env/default/decision) so the demo UI never reports “Source: Unknown.”  
**Verify:** `swift build -v`, `swift test -v`, `swiftformat --lint .`, demo preview showing non-unknown provenance.

## Objective & Scope
Improve diagnostics visibility by ensuring the configuration pipeline records accurate provenance for every resolved value. When bindings read from files or environment variables, the resulting `Snapshot` should indicate the source instead of always defaulting to `.unknown`. Scope includes the binding/applying stage in the pipeline, any supporting `ResolvedValue`/`Provenance` helpers, and the demo UI (“Resolved Values” panel) so it surfaces the richer metadata.

## Constraints & Assumptions
- Avoid introducing new external dependencies—work within `Configuration`, `SpecificationCore`, and the existing pipeline code.
- Preserve deterministic ordering of diagnostics and snapshots (RFC already satisfied elsewhere).
- UI should still compile with the existing `Provenance` enum (no API breaking change).
- Testing strategy reuses existing Swift tests; add new tests for provenance if needed.

## Deliverables
1. Pipeline/binding updates that attach provider identifiers or fallback metadata to `ResolvedValue`.
2. Demo UI rendering “Source: File: config.json”, “Source: Environment”, `Decision fallback`, etc. when available.
3. Unit tests or snapshot assertions validating the new provenance values.
4. Documentation note (README/Tutorial) describing what “Resolved Values” now show.

## Functional Requirements
| ID | Description |
|---|---|
| H9.1 | `Binding.apply` or pipeline captures provider metadata and stores it in `ResolvedValue.provenance` rather than always `.unknown`. |
| H9.2 | Snapshot data is refreshed when decision fallbacks apply so the UI knows when to show `Decision fallback`. |
| H9.3 | Demo UI and documentation reflect the richer provenance (file/env/default/decision). |

## Non-Functional Requirements
- No change to diagnostics ordering or severity (`DiagnosticsReport` should still behave deterministically).
- Keep `ResolvedValue` display helpers simple (avoid heavy formatting).
- Tests cover both configuration file and default/decision sources.

## Subtasks & Acceptance Criteria
- **Track provider info (Medium)**  
  - Enhance `ConfigPipeline` (or bindings) to record where each value came from (provider name, env key, default flag, decision trace).  
  - Acceptance: Snapshot resolved values show `.fileProvider(name: ...)` or `.environmentVariable` when appropriate.
- **Surface new provenance in UI/docs (Low)**  
  - Update `ContentView` and README/Tutorial note so “Resolved Values” show the new metadata clearly.  
  - Acceptance: Manual demo no longer shows “Source: Unknown” for real config entries.
- **Validate via tests (Medium)**  
  - Add or update tests to ensure provenance is set correctly when reading from a file, default, or decision.  
  - Acceptance: Tests pass locally plus existing suite.
- **Validation & polish (Low)**  
  - Run `swift build -v`, `swift test -v`, `swiftformat --lint .`, and `tuist generate`/`xcodebuild test` after the fix.  
  - Acceptance: All commands succeed with the new provenance logic.

## Definition of Done
1. Resolved value provenance reflects actual source (file, env, default, decision) in both pipeline snapshots and UI tooltips.
2. Demo documentation mentions the richer provenance data and explains why “Source” text changed.
3. Validation commands (tuist/xcodebuild, swift build/test, swiftformat) succeed after the implementation.
