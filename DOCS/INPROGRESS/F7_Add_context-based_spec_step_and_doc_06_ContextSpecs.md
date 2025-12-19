# Task PRD: F7 — Add context-based spec step + doc (`06_ContextSpecs.md`)

**Version:** 1.0.0  
**Status:** In Progress  
**Task ID:** F7  
**Priority:** Medium  
**Effort:** M  
**Dependencies:** H3 (context provider support), E3 (demo `AppConfig` and profile)

---

## 1. Objective

Document the v5 “context-based specs” tutorial step so it explicitly teaches how `ContextProviding` and the resulting `EvaluationContext` drive validation when time, feature flags, and counters change the expected result. The PRD must reference the existing `DemoContextProvider`, `AppConfig.profile`’s contextual binding, and the demo UI controls that surface/modify the context, giving readers a runnable recipe that mirrors the demo state already implemented in the repo.

## 2. Scope and Intent

### 2.1 Deliverables

- `Sources/SpecificationConfig/Documentation.docc/Tutorials/06_ContextSpecs.tutorial` rewritten/extended to cover:
  - What `DemoContextProvider` provides (flags, counters, overrides) and how it feeds `SpecProfile.contextProvider`.
  - How the `pet.isSleeping` binding uses `ContextualSpecEntry` to enforce night/day expectations via `context.flag(for:)`.
  - The demo UI affordances (`ConfigManager` summaries, context toggle, diagnostic outcomes) and a runnable validation story (toggle context → observe diagnostics).
- A checklist of verification steps that includes the repo’s required commands (`swift build -v`, `swift test -v`, `swiftformat --lint .`).

### 2.2 Out of Scope

- Re-implementing the demo context features or altering production code beyond what is necessary to describe the current behavior.
- Creating new tutorial files outside of `06_ContextSpecs.tutorial`.

### 2.3 Success Criteria

- The tutorial section explicitly names `DemoContextProvider`, shows the evaluation context fields (date, flags, counters) it supplies, and points to `AppConfig.profile` for wiring.
- The binding example highlights the `ContextualSpecEntry` predicate, references `context.flag(for: "nightTime")`, and clarifies expected diagnostics when context changes.
- UI guidance explains `ConfigManager.contextDescription`, toggle button titles/state, and how to reproduce forced night/day validation via the demo.
- Verification commands succeed once the content change is added.

## 3. Requirements

### 3.1 Functional Requirements

- **FR-1: Context provider narrative (High, M)**  
  - Include text/snippets describing `DemoContextProvider`’s `currentContext()` (flags, counters, optional night override) and how it is exposed through `AnyContextProvider` in `AppConfig.profile`.  
  - **Acceptance:** Tutorial lists the flag/counter keys (`nightTime`, `sleepOverride`, `reloadCount`) and shows the wiring snippet from `AppConfig`.

- **FR-2: Contextual spec instruction (High, M)**  
  - Explain how `ContextualSpecEntry` receives `EvaluationContext`, uses `context.flag(for: "nightTime")`, and emits diagnostics when the context deviates from the config value.  
  - **Acceptance:** Tutorial includes a focused code block (binding snippet) and a description of how wrong context results in diagnostics that the UI surfaces.

- **FR-3: Demo UI walkthrough (Medium, S)**  
  - Detail the left panel elements that show context (`ConfigManager.contextDescription`), the “Force Night Mode / Clear Night Override” toggle, and how diagnostics respond to context flips.  
  - **Acceptance:** Tutorial explains the manual toggle/reload flow, references `ConfigManager.toggleNightMode()` + `ConfigManager.loadConfig()`, and mentions expected behavior (night context allows `isSleeping == true`, day context rejects it with diagnostics).

### 3.2 Non-Functional Requirements

- **NFR-1: Clarity and consistency**  
  - Use the same terminology as PRD §5 (ContextProviding, EvaluationContext, ContextualSpecEntry). No placeholder text allowed; every statement must map to concrete repo artifacts.
- **NFR-2: Verification coverage**  
  - The documentation update must finish with the standard repo validation commands spelled out for readers.

## 4. Execution Plan (Checklist)

- [ ] Audit `DemoContextProvider.swift`, `AppConfig.swift`, `ConfigManager.swift`, and `ContentView.swift` to capture the facts needed for FR-1 through FR-3.  
- [ ] Expand `Sources/SpecificationConfig/Documentation.docc/Tutorials/06_ContextSpecs.tutorial` with sections that cover:
  - Why context providers matter and what data the demo exposes.
  - How the `pet.isSleeping` binding uses `ContextualSpecEntry` alongside the context flag.  
  - How the demo UI surfaces context state and how to trigger day/night diagnostics.
- [ ] Append a “Validation” block with the commands `swift build -v`, `swift test -v`, and `swiftformat --lint .`.
- [ ] Review the tutorial text for alignment with the `/Demo/ConfigPetApp` code (including button labels and context summary strings).
- [ ] Run `swift build -v`, `swift test -v`, and `swiftformat --lint .` to prove the docs-only change leaves the repo healthy; capture any issues for follow-up.

## 5. Acceptance Criteria

- The tutorial describes the context provider, binding, and UI, each tied to matching code locations (`DemoContextProvider`, `AppConfig.profile`, `ConfigManager`).  
- Readers can follow the doc to toggle context and predict the diagnostics that will appear.  
- Repo validation commands succeed after editing the documentation.

## 6. Definition of Done

- Checklist (Section 4) fully checked.  
- Tutorial file updated and saved under `Sources/SpecificationConfig/Documentation.docc/Tutorials/06_ContextSpecs.tutorial`.  
- `DOCS/INPROGRESS/F7_Add_context-based_spec_step_and_doc_06_ContextSpecs.md` still reflects work-in-progress state until ARCHIVE.  
- Verification commands (`swift build -v`, `swift test -v`, `swiftformat --lint .`) executed successfully.  
