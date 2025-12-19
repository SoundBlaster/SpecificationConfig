# Task PRD — H4: Demo v5 — context-based specs

**Source:** PRD §9 (Phase H)  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** H3, E3  
**Output:** ConfigPet demo marked as v5 with at least one EvaluationContext-driven spec + UI indicators  
**Verify:** `tuist generate` (picks up demo), `swift build -v`, `swift test -v`, `swiftformat --lint .`, manual demo verification (reload)

## Objective & Scope
Demonstrate context-aware validation in ConfigPet by treating the demo configuration as a v5 tutorial step. The demo should inject an `EvaluationContext` (via `ContextProviding`) and expose at least one context-driven spec/fallback so the UI can show how evaluation depends on time, flags, counters, etc. Scope includes the demo target (`Demo/ConfigPetApp`), its project/tuist manifest, and any supporting tutorial/docs updates; the library work (context provider support) is already done in H3.

## Constraints & Assumptions
- Keep existing demo features (binding/state display, error UI) intact while adding v5 behaviors.
- Use ASCII-only content for new docs/comments.
- Avoid adding new dependencies beyond existing tooling; use `DefaultContextProvider`, `StaticContextProvider`, or simple `ContextProviding` closures.
- Verify manual UI flows (reload) after implementing the context spec.

## Deliverables
1. A background `ContextProviding` instance used by the demo (e.g., `DemoContextProvider.current` or inline provider) that returns time/flag/counter data.
2. Context-driven spec attached to a `Binding` or decision fallback that can succeed/fail depending on runtime context.
3. Demo UI updates (text, error state, snapshots) that highlight the context-driven value (e.g., “Context: night” or “Flag-enabled”).
4. Updated tutorials/docs describing v5 context-based step, how to configure the provider, and what UI to expect.
5. Validation commands (build/test/SwiftFormat) run and pass.

## Functional Requirements
| ID | Description |
|---|---|
| H4.1 | Demo project wires a `ContextProviding` provider (`DefaultContextProvider` or custom) into `AppConfig.profile` so context-aware specs use it. |
| H4.2 | At least one spec consumed by the demo depends on `EvaluationContext` (time/flag/counter) and changes validation/outcome based on context values. |
| H4.3 | Demo UI surfaces the context-driven result (status label, error, tooltip, etc.) so users understand context influence. |
| H4.4 | Tutorials/docs (`DOCS/.../06_ContextSpecs`) describe how the demo relates to the context spec and how to reproduce the behavior. |

## Non-Functional Requirements
- Pipeline behavior already supports context specs; don’t regress deterministic diagnostics.
- Demo must continue to work with `ConfigReader` reloads and show errors when context-based specs fail.
- All changes should be explainable in doc comments (DocC-friendly) and follow existing style (Swift + Markdown).

## Subtasks & Acceptance Criteria
- **Inventory demo context consumers (High)**  
  - Review `Demo/ConfigPetApp/AppConfig.swift` to identify fields that can reflect context (e.g., `isSleeping`).  
  - Acceptance: Decision on which field demonstrates context-driven behavior is made and documented.
- **Add ContextProviding glue (Medium)**  
  - Introduce a provider (e.g., `DemoContextProvider`) that implements `ContextProviding` or adapts existing demo state, providing `EvaluationContext` data (flags, time-based counters).  
  - Acceptance: Provider is accessible to `AppConfig.profile` (through `contextProvider:` parameter).
- **Add context-aware spec(s) (High)**  
  - Attach `ContextualSpecEntry` to one of the demo bindings or final spec(s) so the resolved value or diagnostics change when context changes (e.g., require `kitsEnabled` flag).  
  - Acceptance: Demo config builds pass/fail depending on context values; tests can simulate both.
- **Update demo UI/docs (Medium)**  
  - Extend `ContentView` (or new detail) to show the current context status (icon/text) and the effect on configuration values.  
  - Update tutorials/docs (DocC step `06_ContextSpecs` or v5 doc) to describe how to reproduce context spec behavior.  
  - Acceptance: Manual check shows UI context indicator; docs describe steps.
- **Validation & polish (Low)**  
  - Run demo’s `tuist generate`, `swift build -v`, `swift test -v`, `swiftformat --lint .`.  
  - Acceptance: Commands pass (SwiftFormat may still only flag generated files).

## Definition of Done
1. Demo uses a context provider with `EvaluationContext` for at least one spec.
2. Context-driven validation is visible in the UI and reproduces with modified context data.
3. DocC tutorial for context specs references the demo changes.
4. `swift build -v`, `swift test -v`, and `swiftformat --lint .` pass locally.
5. Task PRD moved to `DOCS/TASKS_ARCHIVE` with index/workplan updated (handled once H4 is done).
