# Task PRD — H7: Surface spec metadata & decision trace in demo UI

**Source:** PRD §9 (Phase H)  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** H3, H4  
**Output:** Demo UI and docs surface spec metadata + decision trace details derived from the SpecificationConfig pipeline  
**Verify:** `tuist generate`, `swift build -v`, `swift test -v`, `swiftformat --lint .`, manual UI verification (diagnostics + decision trace visibility)

## Objective & Scope
Improve the Config Pet demo’s observability by revealing the metadata that powers diagnostics (spec descriptions/type names) and by showing decision trace information (which fallback produced a value). Scope includes the demo target, its `ContentView` diagnostics panel, `ConfigManager`, and any supporting documentation updates so developers can quickly understand why a spec failed and how decisions behaved.

## Constraints & Assumptions
- Use existing `SpecMetadata`, `DiagnosticItem.context`, and `DecisionTrace` data that the pipeline already provides.
- Keep the UI readable: hide extra metadata when there are no diagnostics or decision traces.
- No new dependencies; rely on SpecificationConfig/Sources metadata.
- Maintain ASCII-only content and follow existing style guidance.

## Deliverables
1. `ConfigManager` exposes snapshot details (resolved values, provenance, decision traces) and helpers for spec metadata so the view layer can read them easily.
2. `ContentView` shows spec metadata (display name/type) alongside diagnostics and adds sections for resolved values and decision traces with provenance/timestamps.
3. Documentation (demo README or new note) explains that the demo now surfaces spec metadata and decision trace details.
4. Validation commands run (`tuist generate`, `swift build -v`, `swift test -v`, `swiftformat --lint .`).

## Functional Requirements
| ID | Description |
|---|---|
| H7.1 | `ConfigManager` surfaces `DiagnosticItem.context` metadata (spec description/type) and `Snapshot.decisionTraces`. |
| H7.2 | Diagnostic rows in `ContentView` render spec metadata when available. |
| H7.3 | Add UI sections for “Resolved Values” (key/value + provenance) and “Decision Trace” (key + matched decision name/type + index). |

## Non-Functional Requirements
- Preserve deterministic diagnostics ordering.
- UI should remain responsive; avoid heavy formatting or new dependencies.
- Document updates should follow existing templates/language.

## Subtasks & Acceptance Criteria
- **Expose pipeline metadata (Medium)**  
  - Add computed properties or helpers in `ConfigManager` to surface snapshot resolved values and decision traces.  
  - Acceptance: View layer can read spec metadata context and trace list without reaching into `buildResult`.
- **Render metadata in the demo UI (High)**  
  - Update `ContentView` diagnostic list to show spec metadata info text.  
  - Add new sections for resolved values/provenance and decision trace summaries.  
  - Acceptance: Manual demo shows spec metadata text per error and the new sections appear when data exists.
- **Document the behavior (Low)**  
  - Update `Demo/README.md` (or tutorial note) to mention the new UI diagnostics and what they show.  
  - Acceptance: Documentation references spec metadata + decision trace observability.
- **Validation & polish (Low)**  
  - Run `tuist generate`, `swift build -v`, `swift test -v`, `swiftformat --lint .`.  
  - Acceptance: Commands succeed (allowing known SwiftFormat warnings in generated files).

## Definition of Done
1. Config Pet UI surfaces spec metadata and decision trace details during failures/successes.
2. Documentation briefly describes how the demo shows metadata and traced decisions.
3. Required validation commands were run locally (`tuist`, `swift build -v`, `swift test -v`, `swiftformat --lint .`).

**Archived:** 2025-12-19
