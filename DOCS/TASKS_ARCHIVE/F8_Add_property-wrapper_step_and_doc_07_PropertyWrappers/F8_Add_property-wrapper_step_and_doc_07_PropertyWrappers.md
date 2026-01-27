# Task PRD: F8 — Add property-wrapper step + doc (`07_PropertyWrappers.md`)

**Version:** 1.0.0  
**Status:** In Progress  
**Task ID:** F8  
**Priority:** Low  
**Effort:** M  
**Dependencies:** H2 (DecisionBinding/DecisionTrace), E3 (demo `AppConfig` + profile)

---

## 1. Objective

Document the v6 property-wrapper tutorial step so it teaches how `@Satisfies` and `@Decides` from SpecificationCore can be layered on top of the existing Config Pet context system. The tutorial must be grounded in the repo’s current context model (`DemoContextProvider`, `EvaluationContext`) and show readers how to attach wrappers to context-aware specs without modifying the core pipeline.

## 2. Scope and Intent

### 2.1 Deliverables

- A new tutorial file at `Sources/SpecificationConfig/Documentation.docc/Tutorials/07_PropertyWrappers.tutorial` that covers:
  - What `@Satisfies` and `@Decides` are for (quick, local evaluation of specs/decisions).
  - How to connect wrappers to `DemoContextProvider` (provider-based initializer) and `EvaluationContext` (`PredicateSpec`, `FirstMatchSpec`).
  - A runnable “toggle context → observe wrapper values” walkthrough that mirrors Config Pet’s night/day context behavior.
- Tutorial snippet files under `Sources/SpecificationConfig/Documentation.docc/Tutorials/07_PropertyWrappers/` used by `@Code` blocks.
- Tutorial map updates to include the new step (`Tutorials.tutorial`) and the landing page tutorial list (`Documentation.docc/SpecificationConfig.md`).
- A validation section listing `swift build -v`, `swift test -v`, and `swiftformat --lint .`.

### 2.2 Out of Scope

- Implementing new demo UI or runtime behavior (property wrappers are documentation-only in this task).
- Adding new public API surface to `SpecificationConfig` beyond documentation updates.

### 2.3 Success Criteria

- The tutorial explicitly references `@Satisfies` and `@Decides`, and calls out their SpecificationCore origin.
- The tutorial includes snippets that compile as standalone examples (imports + minimal types) and show:
  - `@Satisfies(provider: DemoContextProvider.shared, using: PredicateSpec<EvaluationContext>.flag("nightTime"))`
  - `@Decides(provider: DemoContextProvider.shared, firstMatch: [...], fallback: ...)`
- The tutorial map and landing page list include the new step.
- Validation commands succeed after the documentation change.

## 3. Requirements

### 3.1 Functional Requirements

- **FR-1: Wrapper overview (Medium, M)**  
  Explain what `@Satisfies` and `@Decides` evaluate (boolean specs vs decision specs) and how they complement the pipeline.
  - **Acceptance:** Tutorial text explicitly states that wrappers live in `SpecificationCore` and can be used alongside `SpecificationConfig`.

- **FR-2: Context-based wrapper usage (High, M)**  
  Show wrapper initialization that uses `DemoContextProvider` and `EvaluationContext` flags/counters.
  - **Acceptance:** Tutorial includes code snippets that mention `DemoContextProvider.shared` and `PredicateSpec<EvaluationContext>`.

- **FR-3: Decision wrapper walkthrough (Medium, S)**  
  Provide a `@Decides` example that demonstrates fallback behavior and uses a night/day decision spec (or `FirstMatchSpec` list).
  - **Acceptance:** Tutorial explains how to interpret the fallback vs `$projectedValue` (optional) outcome.

- **FR-4: Verification block (Low, S)**  
  End with the standard verification commands.
  - **Acceptance:** `swift build -v`, `swift test -v`, `swiftformat --lint .` listed in the Validation section.

### 3.2 Non-Functional Requirements

- **NFR-1: Repo accuracy**  
  All references must match concrete files and types in this repo and its dependencies (`SpecificationCore`).
- **NFR-2: Consistent terminology**  
  Use the same naming as earlier tutorials (`EvaluationContext`, `ContextProviding`, `ContextualSpecEntry`).

## 4. Execution Plan (Checklist)

- [ ] Review SpecificationCore wrapper APIs (`Satisfies`, `Decides`, `PredicateSpec`, `FirstMatchSpec`) for accurate examples.
- [ ] Create `07_PropertyWrappers.tutorial` with sections for wrapper overview, `@Satisfies`, `@Decides`, and validation.
- [ ] Add snippet files under `Tutorials/07_PropertyWrappers/` referenced by `@Code` blocks.
- [ ] Update `Tutorials.tutorial` and `SpecificationConfig.md` to include the new tutorial step.
- [ ] Run `swift build -v`, `swift test -v`, `swiftformat --lint .`.

## 5. Acceptance Criteria

- The new tutorial step is linked from the tutorial map and landing page list.
- Each `@Code` block points to a real file and uses `.swift` in `name:` for syntax highlighting.
- The documentation clearly explains wrapper usage with `DemoContextProvider` and expected outcomes when context changes.
- Repo validations are green after the doc change.

## 6. Definition of Done

- Checklist in Section 4 complete.
- `Sources/SpecificationConfig/Documentation.docc/Tutorials/07_PropertyWrappers.tutorial` exists and is populated.
- `DOCS/INPROGRESS/F8_Add_property-wrapper_step_and_doc_07_PropertyWrappers.md` remains In Progress until archived.
- Validation commands executed successfully.

**Archived:** 2026-01-26
