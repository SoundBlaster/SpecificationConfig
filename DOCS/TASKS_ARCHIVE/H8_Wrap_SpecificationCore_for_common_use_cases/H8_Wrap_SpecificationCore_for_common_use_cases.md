# Task PRD — H8: Wrap SpecificationCore for common use cases

**Source:** PRD §9 (Phase H)  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** H1, H2, H3  
**Output:** Application code can stay inside `SpecificationConfig` while still using metadata-rich specs, contextual predicates, and decision traces, reducing the need to import `SpecificationCore`.  
**Verify:** Unit tests covering the new wrappers + updated docs demonstrating the simpler import surface.

## Objective & Scope
Reduce the cognitive load for downstream apps (like Config Pet) by providing small, purpose-built wrappers that expose `SpecEntry`, `ContextualSpecEntry`, `DecisionBinding`, and `ContextProviding` abstractions without forcing every consumer to import `SpecificationCore`. The wrappers should favor the common scenarios (value specs with metadata, context-aware specs, decision fallbacks) and re-export the metadata needed for diagnostics. Scope includes the `SpecificationConfig` library surface and its documentation.

## Constraints & Assumptions
- No new external dependencies beyond the existing `SpecificationCore`/`Swift Configuration`.
- Keep wrappers minimal so they can be reviewed alongside the existing API.
- Provide documentation for each wrapper showing how to achieve common patterns without touching `SpecificationCore`.
- Keep the API compatible with the new H7 UI surface (metadata + decision trace) so apps can continue to surface those details.

## Deliverables
1. One or more wrapper helpers/aliases inside `SpecificationConfig` that re-export or wrap `SpecificationCore` types (e.g., `SpecEntry`, `ContextualSpecEntry`, `DecisionBinding`, `DemoContextProvider` helpers) with lightweight convenience initializers.
2. Updated documentation (tutorial or README) showing how to use the wrapper API from an app that only imports `SpecificationConfig`.
3. Unit tests (or doc-driven examples) validating that the wrappers behave the same as the raw SpecificationCore counterparts.

## Functional Requirements
| ID | Description |
|---|---|
| H8.1 | `SpecificationConfig` exposes metadata-aware spec helpers so clients do not need to import `SpecificationCore` for common cases. |
| H8.2 | Wrappers for contextual specs and decisions capture the same metadata needed by diagnostics/trace UI. |
| H8.3 | Supporting docs show the simplified import surface and include quickstart snippets referencing the new helpers. |

## Non-Functional Requirements
- Keep the wrapper API stable (no breaking changes after release).
- Tests demonstrate parity between wrapper behavior and the underlying SpecificationCore spec evaluations.
- Documentation uses the existing DocC/tutorial style.

## Subtasks & Acceptance Criteria
- **Propagate metadata-aware wrappers (Medium)**  
  - Introduce wrappers or factory helpers for `SpecEntry`, `ContextualSpecEntry`, and `DecisionBinding` inside `SpecificationConfig`.  
  - Acceptance: The wrappers can be used instead of the raw types without dropping metadata.
- **Document the simplified import surface (Low)**  
  - Update README or tutorial to show how apps can rely only on `SpecificationConfig` while still wiring context-aware specs and decisions.  
  - Acceptance: Documentation highlights the wrappers and includes copyable code snippets.
- **Validate via tests/examples (Low)**  
  - Add unit tests or DocC examples ensuring wrappers behave like the `SpecificationCore` originals (metadata captured, context used, decisions traced).  
  - Acceptance: Tests pass and rely only on `SpecificationConfig`.
- **Validation & polish (Low)**  
  - Run `swift build -v`, `swift test -v`, and `swiftformat --lint .` again if wrapper work changes formatting.  
  - Acceptance: Commands succeed (same output as before).

## Definition of Done
1. App consumers can import only `SpecificationConfig` for the targeted use cases.
2. Documentation demonstrates the simplified API and how spec metadata and decision trace data is preserved.
3. `swift build -v`, `swift test -v`, and `swiftformat --lint .` remain green after wrapper changes.

**Archived:** 2025-12-19
