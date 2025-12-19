# Task PRD — H10: Display overrides panel in demo

**Source:** PRD §9 (Phase H)  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** H7, H9  
**Output:** New UI region lists active overrides (temporary sleep override, future manual tweaks) alongside provenance information so developers distinguish pipeline readings from hand-applied values.  
**Verify:** Manual interaction with the demo (toggle the wake-up override) shows the override panel updating, plus existing `swift build -v`, `swift test -v`, `swiftformat --lint .` remain green.

## Objective & Scope
Provide a separate “Overrides” component that surfaces temporary or manual values that are layered on top of the resolved snapshot (e.g., the sleep override triggered by the button). The panel should clearly show what key is overridden, the override value, and why (manual override), without confusing users by mutating the resolved-values provenance. Scope includes UI layout, data plumbing in `ConfigManager`, and documentation describing when to consult the overrides panel.

## Constraints & Assumptions
- The primary “Resolved Values” panel should continue to reflect what `ConfigPipeline` read or decided; overrides are additional, not replacements.  
- Override data is owned by the demo (e.g., `sleepOverride`) and should be tracked separately from the config reader snapshot for provenance accuracy.  
- The override UI should remain simple and not duplicate the entire snapshot; highlight only keys that have active manual adjustments.

## Deliverables
1. Demo UI component (new section) summarizing active overrides with their keys, values, and a source label such as “Manual override.”  
2. `ConfigManager` (or related state) exposes the override list to the UI and keeps it in sync with the override lifecycle (auto-clear when the override expires).  
3. Documentation note (demo README or inline comment) describing how overrides differ from resolved values.

## Functional Requirements
| ID | Description |
|---|---|
| H10.1 | Override metadata (key, value, description) is derived from the demo’s manual overrides and exposed to the UI. |
| H10.2 | Override panel updates immediately when overrides activate/deactivate (e.g., hitting “Wake up for 10s”). |
| H10.3 | Override entries clearly label their provenance (e.g., “Manual override”). |

## Non-Functional Requirements
- Keep the override panel visually distinct from the resolved-values list to avoid confusion.  
- Maintain accessibility (caption text, contrast) consistent with the rest of the demo.  
- Performance impact should be negligible—overrides are few and updated infrequently.

## Subtasks & Acceptance Criteria
- **Surface override data (Medium)**  
  - `ConfigManager` exposes a computed list of active overrides.  
  - Acceptance: “Wake up for 10s” adds an entry to the override list (key, value, label).  
- **Add override UI component (Medium)**  
  - Insert a new SwiftUI section near “Resolved Values” showing overrides or a placeholder when none exist.  
  - Acceptance: panel shows up-to-date overrides and disappears when there are none.  
- **Document override semantics (Low)**  
  - Update demo README (or inline UI comment) explaining that overrides are not part of the resolved snapshot.  
  - Acceptance: README mentions the purpose of the override panel.

## Definition of Done
1. Demo UI shows manual override list separate from resolved values, and the list reacts to the plus/minus of overrides (wake-up button).  
2. Documentation clarifies that the override panel is the real-time state distinct from the config provenance.  
3. Validation commands (`swift build -v`, `swift test -v`, `swiftformat --lint .`) continue to pass after the UI additions.

**Archived:** 2025-12-19
