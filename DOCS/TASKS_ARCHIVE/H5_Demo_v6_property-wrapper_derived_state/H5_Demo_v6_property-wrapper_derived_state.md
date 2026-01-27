# Task PRD: H5 — Demo v6: property-wrapper derived state

## Context & Assumptions
- The Config Pet demo already ships with context-based specs (H3/H4) and decision bindings (H2) wired through `DemoContextProvider.shared`.
- Property wrappers `@Satisfies` and `@Decides` live in SpecificationCore and evaluate against the same `EvaluationContext` used by the pipeline.
- The demo target currently imports `SpecificationConfig` and should remain focused on demo-only UX changes.

## Selected Task (ID, Title, source)
- **ID:** H5
- **Title:** Demo v6: property-wrapper derived state
- **Source:** PRD §9 (Phase H)

## PRD §9 Row Data (priority/effort/deps/outputs)
- **Priority:** Low
- **Effort:** M
- **Inputs:** SpecificationCore wrappers
- **Output:** Demo uses `@Satisfies` / `@Decides`
- **Dependencies:** H2, E3
- **Verify:** Manual demo

## Implementation Plan (phased)
1. **Derived state model**
   - Add a demo-only helper type that uses `@Satisfies` and `@Decides` with `DemoContextProvider.shared`.
   - Use `PredicateSpec<EvaluationContext>.flag("nightTime")` and `PredicateSpec<EvaluationContext>.flag("sleepOverride")` to mirror the tutorial examples.
2. **Wire into ConfigManager**
   - Hold a single instance of the derived state helper in `ConfigManager`.
   - Expose computed properties for the derived boolean, derived label, and decision match (projected value).
3. **Surface in UI**
   - Add a “Derived State” section to `ContentView` that displays the derived boolean and decision label, plus a fallback/match hint.
4. **Documentation/task tracking**
   - Mark checklist items complete in this task PRD.
   - Update `DOCS/Workplan.md` and `DOCS/INPROGRESS/next.md` after validation.

## Files & Change Points (Sources/Tests)
- `Demo/ConfigPetApp/ConfigPetApp/DemoDerivedState.swift` (new): property-wrapper derived state helper.
- `Demo/ConfigPetApp/ConfigPetApp/ConfigManager.swift`: expose derived-state accessors for UI.
- `Demo/ConfigPetApp/ConfigPetApp/ContentView.swift`: add derived-state UI panel.
- `DOCS/Workplan.md`: mark H5 complete (post-validate).
- `DOCS/INPROGRESS/next.md`: update status (post-validate).

## Affected API Surface (types/functions/modules)
- **New:** `DemoDerivedState` (demo module only).
- **ConfigManager additions:** derived state accessors (computed properties).
- **UI:** new `Derived State` section in `ContentView`.

## Subtasks Checklist (atomic)
- [x] Create `DemoDerivedState` with `@Satisfies` and `@Decides` wrappers tied to `DemoContextProvider.shared`.
- [x] Add derived-state accessors to `ConfigManager` for UI use.
- [x] Render derived state in `ContentView` with match/fallback messaging.
- [x] Run CI-matching validation commands.
- [x] Update task tracking docs (`next.md`, `Workplan.md`).

## Acceptance Criteria (per subtask)
- Derived state helper compiles and evaluates using `EvaluationContext` flags (`nightTime`, `sleepOverride`).
- `ConfigManager` exposes derived boolean, label, and match/fallback info without breaking existing bindings.
- UI displays derived state and updates when night override toggles/reloads.
- `swift build -v` and `swift test -v` complete successfully; `swiftformat --lint .` passes if available.
- Task tracking reflects completion.

## Verification Commands (repo-accurate, from CI)
- `swift build -v`
- `swift test -v`
- `swift test --sanitize=thread`
- `swiftformat --lint .` (if installed)

## Definition of Done (aligned with PRD §12)
- Demo app builds and shows derived state backed by `@Satisfies`/`@Decides`.
- CI-equivalent checks are green.
- Task tracking updated so H5 is no longer pending.

## Risks & Open Questions
- **Dependency exposure:** Demo may need direct access to SpecificationCore types; adjust imports if the module is not visible via transitive dependencies.
- **UI refresh:** Derived values are computed on access; ensure UI refreshes when context changes (reload/night override).

**Archived:** 2026-01-27
