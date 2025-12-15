# PRD: SpecificationConfig — Swift Configuration wrapper powered by SpecificationCore

> **Project codename:** Config Pet  
> **Primary outcome:** A Swift package that wraps **apple/swift-configuration** with a **SpecificationCore-driven**, explicitly injected, fully type-safe configuration pipeline — plus a macOS demo app and a tutorial-style article that incrementally builds the app.

---

## 0. Executive summary

This project creates a Swift Package (`SpecificationConfig`) that sits between:

- **Swift Configuration** (apple/swift-configuration): *reading config from providers / layered sources*.
- **SpecificationCore** (SoundBlaster/SpecificationCore): *expressing validation and decision logic as composable specifications*.

The wrapper must be configured **explicitly from the Application layer**. The wrapper **must not** contain business-domain configuration types or specifications. Instead, the Application supplies:

- the `FinalConfig` type (e.g., `AppConfig`)
- a `DraftConfig` type (optional-first “assembly” type)
- a typed mapping of config keys → decoding → `WritableKeyPath` into Draft
- value-level specs (validate each decoded value)
- final specs (validate cross-field invariants)
- optional decision specs for fallback/derivation

Additionally, the repository includes a macOS demo app (**Config Pet**) and a popular tutorial article showing step-by-step implementation from a minimal “Tamagotchi” to a more complex config-driven system.

---

## 1. Scope and intent

### 1.1 Objective (precise)

Implement an SPM package **SpecificationConfig** that provides a **generic, key-path based, explicitly injected** configuration build pipeline:

1. Read values from `ConfigReader` (Swift Configuration).
2. Decode values into typed `Value`.
3. Validate each value with injected **SpecificationCore** specs.
4. Populate a `Draft` object via `WritableKeyPath`.
5. Finalize to a strict `FinalConfig` type using an injected `finalize(Draft) -> FinalConfig`.
6. Validate final config with injected cross-field specs.
7. Produce a **deterministic** output (either `FinalConfig` or a structured error report).

**Deliver** a macOS demo app that uses the wrapper to power a “Tamagotchi” UI, starting from a tiny config (`name` + `isSleeping`) and growing in stages.

### 1.2 Primary deliverables

| Deliverable | Type | Description | Success criteria |
|---|---|---|---|
| `SpecificationConfig` package | SPM library | Wrapper module integrating Swift Configuration with SpecificationCore via explicit injection | Builds on macOS; public API is generic & typed; zero domain coupling |
| `Config Pet` demo app | macOS app target | UI demonstrates “config → pet state” with incremental complexity | Runs locally; shows name + sleeping state; reload updates UI |
| Tutorial article | Apple DocC  Tutorials | Step-by-step tutorial aligned with repo commits/tags | Reader can follow and reproduce; each step is verifiable |
| Test suite | XCTest | Unit tests for pipeline: decoding, binding, validation, error reporting, determinism | CI green; coverage for core behaviors |
| Diagnostics model | Swift types | Machine-readable error + provenance model suitable for UI display | Errors include key, source, decode failure, spec failures |

### 1.3 Non-goals

- No attempt to replace Swift Configuration or duplicate providers.
- No runtime reflection-based auto-registration.
- No implicit “magic” that hides where specs come from.
- No secret-management product or vault provider implementation (demo can mock).
- No cross-platform UI demo (macOS only for now).

### 1.4 Constraints

- **Explicit injection**: Application must define the schema/profile/specs. Wrapper must not “discover” business configuration automatically.
- **Terminology**: Use **Spec / Specification** and **SpecProfile / SpecSet**. Avoid `Rule` in Application-level naming.
- **Swift feature usage**: Use generics, key-paths, protocols, associated types, and type erasure as needed.
- **Compatibility**: Target macOS version compatible with Swift Configuration (documented minimum; keep configurable in Package.swift).
- **No unclear behavior**: All defaults, precedence, and fallbacks must be explicit.

### 1.5 External dependencies

- `apple/swift-configuration` (Configuration module)
- `SoundBlaster/SpecificationCore`

---

## 2. Users & primary use-cases

### 2.1 Personas

1. **App engineer (Application owner)**  
   Wants strict typed config at startup, with validation and useful diagnostics.

2. **Library author**  
   Wants to depend on a consistent config reading API without dictating provider choices.

3. **DevOps / CI engineer**  
   Wants deterministic, testable configuration loading and clear failure messages.

### 2.2 Core user stories

- As an app engineer, I can define a typed `AppConfig` and get it built from config sources without using stringly-typed reads throughout the codebase.
- As an app engineer, I can define per-field specs (e.g., non-empty string, range) and cross-field specs (e.g., consistent combinations).
- As a developer, when config is invalid, I get a structured report including failing key(s), decoding errors, and spec failures.
- As a demo user, I can edit `config.json` and click “Reload” (and later enable watch) to see the pet change immediately.

---

## 3. Product requirements

### 3.1 Functional requirements (wrapper library)

#### FR-1: Typed bindings with key-path mapping
- Provide a way to define a binding:
  - `key: String`
  - `path: WritableKeyPath<Draft, Value?>`
  - `read/decode: (ConfigReader, String) throws -> Value?` (or a more structured decoder protocol)
  - `defaultValue: Value?`
  - `valueSpecs: [AnySpecification<Value>]`
- The pipeline must:
  - read the key
  - decode typed value
  - validate typed value against each `valueSpec`
  - write the resulting `Value` into `Draft` via key-path

**Acceptance criteria**
- Given a `Draft` with `nil` fields and bindings, after pipeline load, fields are set to expected typed values.
- When decode fails, `Draft` must not be mutated for that field, and a decode error entry is produced.

#### FR-2: Explicit spec injection and execution
- Accept value-level specs and final config specs as injected arrays.
- Run value-level specs per binding on the decoded value.
- Run final config specs on finalized `FinalConfig`.

**Acceptance criteria**
- A failing value spec surfaces as a structured error containing key, value representation, spec identifier/name.
- A failing final spec surfaces as a structured error containing spec identifier/name and a human-readable message.

#### FR-3: Finalization step
- Application supplies:
  - `finalize(Draft) throws -> FinalConfig`
- Pipeline calls `finalize` only after all bindings attempt to load (unless configured to fail-fast; default: collect all errors).
- If finalize throws, capture finalize error.

**Acceptance criteria**
- Missing required keys can be enforced in `finalize` and reported as structured missing-key errors.

#### FR-4: Deterministic error reporting
- Output must be deterministic for the same inputs:
  - stable ordering of errors (e.g., by key, then stage)
  - stable formatting of diagnostics
- Provide `ConfigBuildResult<FinalConfig>` = `.success(FinalConfig, snapshot)` or `.failure(report)`.

**Acceptance criteria**
- Golden tests prove identical error ordering across runs.

#### FR-5: Provenance / source information (minimum viable)
- Record for each resolved key:
  - resolved value source (provider identifier, e.g., ENV vs File vs Defaults)
- Expose in `Snapshot` for UI use.
- If provider info is unavailable, at minimum mark as `.unknown`.

**Acceptance criteria**
- Demo can show “Resolved From: File” for `config.json`.

#### FR-6: Reload support (manual first)
- Provide an API to rebuild config on demand using the same profile and reader.

**Acceptance criteria**
- Demo’s “Reload” button triggers rebuild and updates UI state.

---

### 3.2 Functional requirements (demo app: Config Pet)

#### Demo FR-1: MVP state
- The pet has:
  - `name`
  - `isSleeping` (sleeping or awake)
- UI shows:
  - left pane: current config key-values (resolved)
  - right pane: pet view reflecting state

**Acceptance criteria**
- Running app with a `config.json` displays correct name and sleeping status.

#### Demo FR-2: Progressive steps
The demo must be implemented in incremental “tutorial steps”:

| Step | Feature | Purpose |
|---|---|---|
| v0 | name + isSleeping; single file provider; reload button | minimal end-to-end |
| v1 | ENV overrides file | demonstrate provider precedence |
| v2 | value specs (non-empty name) + error UI | demonstrate Spec usage |
| v3 | decision fallback for isSleeping when missing | demonstrate DecisionSpec |
| v4 | optional watch/hot reload | demonstrate watching updates |

**Acceptance criteria**
- Each step corresponds to a git tag or branch.
- Tutorial references the same tags.

#### Demo FR-3: Error presentation (minimal)
- If config invalid:
  - show an “Error” panel with a list of issues
  - pet shows a “sick/???” placeholder state

**Acceptance criteria**
- Empty name produces visible error and prevents building `AppConfig`.

---

### 3.3 Non-functional requirements

#### NFR-1: Reliability
- Pipeline must not partially apply invalid values silently.
- Draft updates for a key occur only after successful decode + value-spec pass.

#### NFR-2: Performance
- No heavy reflection.
- O(N) in number of bindings.
- Avoid repeated reads per key (exactly once per binding).

#### NFR-3: Security / secrets hygiene
- Provide a way to mark a binding as “secret” for redaction in diagnostics.
- Demo can include a fake secret but must not print raw secret in UI/logs.

#### NFR-4: Testability
- All core pipeline logic must be unit-testable without UI.
- Provide a fake `ConfigReader` adapter or a minimal provider for tests.

#### NFR-5: Documentation
- Public API must have DocC-style comments (at least for primary types).
- Tutorial must be executable and not rely on unstated context.

---

## 4. Information architecture & terminology

### 4.1 Terms

| Term | Definition |
|---|---|
| **Binding** | A mapping from config key → typed value → draft key-path, plus value specs |
| **Draft** | Intermediate config container with optional fields |
| **FinalConfig** | Strict app-owned config type used by business logic |
| **Spec** | A SpecificationCore Specification validating a value or object |
| **DecisionSpec** | A SpecificationCore decision that computes/chooses a value |
| **SpecProfile** | A named set of bindings + finalize + final specs |

### 4.2 Public API naming rules

- Use `SpecProfile`, `SpecSet`, or `Profile`. Avoid `Rule`.
- Prefer `ConfigPipeline`, `ConfigBuilder`, `ConfigLoader`.
- Use `Any*` types for type erasure: `AnyBinding<Draft>`.

---

## 5. Technical design (high-level)

### 5.1 Module layout (SPM)

```
Package.swift
Sources/
  SpecificationConfig/
    Binding.swift
    AnyBinding.swift
    SpecProfile.swift
    Pipeline.swift
    Snapshot.swift
    Diagnostics.swift
    Redaction.swift
    Adapters/
      ConfigReader+Helpers.swift
    Documentation.docc/
      Tutorials
        Tutorials.tutorial/
        00_Intro.tutorial
        01_MVP.tutorial
        02_EnvOverrides.tutorial
        03_ValueSpecs.tutorial
        04_Decisions.tutorial
        05_Watching.tutorial
Tests/
  SpecificationConfigTests/
    PipelineTests.swift
    DeterminismTests.swift
Demo/
  ConfigPetApp/   (macOS target; may live as separate Xcode project or workspace)
```

### 5.2 Core types (implementation intent)

#### Binding (generic)
- Stores:
  - key string
  - key-path
  - decode closure
  - default
  - secret flag
  - specs array

#### AnyBinding (type erasure)
- Needed to store heterogeneous `Value` types in a single array.
- Must preserve:
  - key
  - apply-to-draft behavior
  - error production
  - provenance recording

#### Snapshot
- Holds:
  - resolved values (stringified & redacted)
  - resolved source/provenance
  - timing (optional)
  - list of diagnostics items

#### Diagnostics
- Categories:
  - missing key
  - decode error
  - value spec failure
  - finalize error
  - final spec failure

### 5.3 Pipeline algorithm (deterministic)

1. Initialize empty `Snapshot` and `DiagnosticsReport`.
2. For each binding in stable order:
   1) attempt read/decode
   2) if no value and default exists: use default, note provenance `.default`
   3) if value exists: run value specs
   4) on success: write to draft via key-path
   5) on failure: append diagnostic, do not mutate draft
3. If diagnostics contain “fatal” items (configurable; default: any error is fatal):
   - return failure report
4. Call `finalize(draft)`:
   - on error: return failure report
5. Run final specs on `FinalConfig`
6. Return `.success(finalConfig, snapshot)`

---

## 6. User interaction flows (demo app)

### 6.1 MVP flow

1. App launches
2. Reads `config.json`
3. Builds `AppConfig`
4. UI displays config panel (left) and pet state (right)
5. User edits `config.json`
6. User clicks **Reload**
7. App rebuilds and updates UI

### 6.2 Failure flow

1. User sets `pet.name` = `""`
2. Reload triggers rebuild
3. Value spec fails
4. UI shows errors list
5. Pet shows placeholder “confused/sick” state

---

## 7. Edge cases & failure scenarios

| Scenario | Expected behavior | Verification |
|---|---|---|
| Missing `pet.name` | Finalize throws missing-key error; show diagnostics | Unit test + demo |
| `pet.name` empty | Value spec fails; draft not updated; error shown | Unit test + demo |
| Invalid bool value | Decode error; error shown | Unit test |
| ENV overrides file | Snapshot shows resolved source = ENV | Unit test |
| Multiple errors | Report contains all issues in stable order | Determinism test |
| Secret values | Diagnostics show redacted string | Unit test |

---

## 8. Milestones

| Milestone | Output | Definition of done |
|---|---|---|
| M0 Repo skeleton | SPM package + demo app scaffold | Builds locally; CI placeholder |
| M1 MVP pipeline | Bindings + finalize + success path | Basic tests pass |
| M2 Value specs + diagnostics | Spec failures + UI error list | Non-empty name enforced |
| M3 Provider precedence | ENV overrides file | Provenance visible |
| M4 Decision fallback | Missing isSleeping derived | Decision spec demonstrated |
| M5 Tutorial docs | Step-by-step docs with tags | Reproducible |
| M6 Release | 0.1.0 tag | Changelog + README |

---

## 9. Work plan / TODO breakdown (execution-ready)

### Legend
- **Priority:** High / Medium / Low
- **Effort:** S (≤2h), M (½–1d), L (1–3d), XL (3d+)
- **Verify:** Unit tests / Snapshot tests / Manual demo / CI

---

## Phase A — Repository & package scaffolding

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| A1 | Create new repo for wrapper (SPM package) | High | S | GitHub repo | Repo with MIT license, README stub | None | Manual |
| A2 | Add dependencies: swift-configuration + SpecificationCore | High | S | Package.swift | Builds with imports | A1 | CI build |
| A3 | Add `Docs/Tutorial/` structure with placeholder files | Medium | S | Repo | Tutorial skeleton | A1 | Manual |

**Parallelization:** A2 and A3 can run in parallel after A1.

---

## Phase B — Core types: Binding, AnyBinding, Snapshot, Diagnostics

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| B1 | Define `Binding<Draft, Value>` public API | High | M | Requirements | `Binding.swift` | A2 | Unit tests compile |
| B2 | Implement `AnyBinding<Draft>` type erasure | High | L | B1 | `AnyBinding.swift` | B1 | Unit tests |
| B3 | Define `Snapshot` model (values + provenance) | High | M | Requirements | `Snapshot.swift` | B1 | Unit tests |
| B4 | Define `DiagnosticsReport` & error items | High | M | Requirements | `Diagnostics.swift` | B1 | Unit tests |
| B5 | Add `Redaction` support (secret flag) | Medium | M | B4 | `Redaction.swift` | B4 | Unit tests |

**Dependencies:** B2 depends on B1. B3/B4 depend on B1. B5 depends on B4.

---

## Phase C — Pipeline implementation

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| C1 | Implement `SpecProfile<Draft, Final>` | High | M | B1 | `SpecProfile.swift` | B1 | Unit tests |
| C2 | Implement `ConfigPipeline` (build result: success/failure) | High | L | C1 + B2/B3/B4 | `Pipeline.swift` | B2,B3,B4,C1 | Unit tests |
| C3 | Deterministic ordering of diagnostics | High | M | C2 | Stable sorting function | C2 | Golden test |
| C4 | Add “collect-all vs fail-fast” option (default collect-all) | Medium | M | C2 | Pipeline option | C2 | Unit tests |

---

## Phase D — Adapters to Swift Configuration

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| D1 | Add minimal helpers for reading primitives (String/Bool/Int/URL) | High | M | Swift Configuration reader | `ConfigReader+Helpers.swift` | A2 | Unit tests |
| D2 | Provenance capture strategy | High | M | Swift Configuration API | Snapshot source extraction or placeholder | B3,D1 | Unit tests |
| D3 | Manual reload API (rebuild with same profile/reader) | Medium | S | C2 | `rebuild()` | C2 | Manual demo |

---

## Phase E — Demo app (Config Pet) MVP

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| E1 | Create macOS SwiftUI app target (Demo/ConfigPetApp) | High | M | Repo | Buildable app | A1 | Manual |
| E2 | Add config file loader (config.json in app working dir) | High | M | E1 | Reader creation | D1 | Manual |
| E3 | Implement `AppConfig` + `Draft` + `SpecProfile` for v0 | High | M | Wrapper API | Working MVP | C2,E2 | Manual |
| E4 | UI: Split view (Inputs left, Pet right) + Reload button | High | M | E3 | Simple UI | E3 | Manual |
| E5 | UI: error list panel when build fails | High | M | E4 | Error presentation | B4,C2 | Manual |

---

## Phase F — Tutorial & incremental tags

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| F1 | Write `Docs/Tutorial/01_MVP.md` matching v0 | High | M | E3–E5 | Tutorial step | E5 | Manual follow |
| F2 | Tag repo `tutorial-v0` | High | S | Git | Tag/Release | F1 | Manual |
| F3 | Add ENV override step + doc (`02_EnvOverrides.md`) | Medium | M | Swift Configuration providers | v1 + docs | D1,E2 | Manual |
| F4 | Add value specs step + doc (`03_ValueSpecs.md`) | Medium | M | SpecificationCore | v2 + docs | B4,C2 | Manual |
| F5 | Add decision fallback step + doc (`04_Decisions.md`) | Medium | M | DecisionSpec | v3 + docs | C2 | Manual |
| F6 | Optional watching step + doc (`05_Watching.md`) | Low | L | Watching APIs | v4 + docs | E2 | Manual |

---

## Phase G — CI, quality gates, release

| ID | Task | Priority | Effort | Inputs | Output | Dependencies | Verify |
|---|---|---:|---:|---|---|---|---|
| G1 | GitHub Actions: build + test on macOS | High | S | Repo | CI green | C2 | CI |
| G2 | README: “Why this wrapper” + quickstart | High | M | Docs | Solid README | F1 | Manual |
| G3 | 0.1.0 release checklist + changelog | Medium | S | Repo | Release notes | G1,G2 | Manual |

---

## 10. Acceptance test plan (end-to-end)

### 10.1 Wrapper library acceptance
- [ ] Can define `Binding` with `WritableKeyPath` and read typed values into Draft
- [ ] Value specs are executed and can block invalid writes
- [ ] Finalization constructs strict config or throws with structured error
- [ ] Final specs validate cross-field constraints
- [ ] Diagnostics are deterministic and machine-readable
- [ ] Secret values are redacted in diagnostics

### 10.2 Demo app acceptance
- [ ] Running demo reads config.json and displays name + sleeping state
- [ ] Reload button rebuilds and updates UI
- [ ] Invalid config shows errors and pet placeholder

### 10.3 Tutorial acceptance
- [ ] Each tutorial step matches a tag and builds
- [ ] Steps are incremental and reproducible without hidden context

---

## 11. Open questions (must be resolved during implementation)

1. **Provenance API availability:**  
   Determine how Swift Configuration exposes provider/source for a resolved key.  
   If not directly available, implement a minimal provenance layer in the wrapper (e.g., provider order + “first provider that returned value”), or mark as `.unknown` but document limitation.

2. **Watching API choice (optional step):**  
   Pick the simplest watch mechanism that aligns with Swift Configuration’s supported patterns.

---

## 12. Definition of done

Project is “done” when:

- Wrapper library is published as SPM package and tagged `0.1.0`
- Demo app builds and demonstrates MVP + reload
- Tutorial has at least the MVP step and is aligned with a tag
- CI is green and core pipeline has unit tests covering success + failure modes
- Public API is documented and avoids domain coupling

---

## Appendix A — Minimal demo config files

### config.json
```json
{
  "pet": {
    "name": "Egorchi",
    "isSleeping": true
  }
}
```

### .env (v1 step)
```
PET_NAME=OverriddenName
PET_IS_SLEEPING=false
```

---

## Appendix B — Suggested repo naming

- Repo: `SpecificationConfig`
- Demo: `ConfigPetApp`
- Tutorial series: `Sources/Documentation.docc/Tutorials/*`
- 