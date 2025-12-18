# Task PRD: E3 — Implement AppConfig + Draft + SpecProfile for v0

**Version:** 1.0.0
**Status:** Complete
**Task ID:** E3
**Priority:** High
**Effort:** M
**Dependencies:** C2 (ConfigPipeline), E2 (Config file loader)

---

## 1. Objective

Introduce app-specific configuration types for the ConfigPetApp demo and wire them into the wrapper API so the demo reads config.json into a typed AppConfig value.

**Current State:**
- ConfigPetApp reads config.json into a ConfigReader
- UI reads raw values from ConfigReader
- No AppConfig/Draft types or SpecProfile

**Target State:**
- AppConfigDraft and AppConfig types defined for pet config
- SpecProfile configured with bindings for pet.name and pet.isSleeping
- ConfigManager builds AppConfig via ConfigPipeline and exposes results
- UI reads from AppConfig instead of ConfigReader

**Source:** PRD §9 Phase E, Task E3

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. AppConfigDraft struct with optional fields matching config keys
2. AppConfig struct with finalized, non-optional values
3. SpecProfile<AppConfigDraft, AppConfig> definition for v0
4. Integration in ConfigManager to build AppConfig using ConfigPipeline
5. UI update to display AppConfig values

### 2.2 What this task does NOT deliver

- Split-view UI or reload button (E4)
- Error list panel (E5)
- Additional config keys beyond v0 (future tasks)

### 2.3 Success Criteria

- [x] AppConfigDraft and AppConfig types exist in demo target
- [x] SpecProfile binds pet.name and pet.isSleeping
- [x] ConfigManager builds AppConfig using ConfigPipeline
- [x] ContentView shows AppConfig values when build succeeds
- [x] Manual run shows name and sleeping state from config.json
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: AppConfigDraft definition**
- Draft stores optional values for required keys
- Fields: petName (String?), isSleeping (Bool?)

**Acceptance Criteria:**
- Draft is a plain struct in demo target
- Fields are optional to allow binding defaults

**FR-2: AppConfig definition**
- Final config stores non-optional values
- Fields: petName (String), isSleeping (Bool)

**Acceptance Criteria:**
- AppConfig is created from Draft via finalize closure
- Missing required values surface a thrown error

**FR-3: SpecProfile for v0**
- Bindings:
  - pet.name -> Draft.petName (String)
  - pet.isSleeping -> Draft.isSleeping (Bool)
- Uses ConfigReader helpers from SpecificationConfig

**Acceptance Criteria:**
- SpecProfile is defined in demo target
- Bindings use SpecificationConfig Binding/AnyBinding

**FR-4: ConfigManager integration**
- Build AppConfig using ConfigPipeline
- Store build result for UI consumption

**Acceptance Criteria:**
- ConfigManager publishes AppConfig or build error state
- Successful build surfaces AppConfig to views

**FR-5: UI reads AppConfig**
- ContentView renders pet name and sleeping state from AppConfig

**Acceptance Criteria:**
- When config.json is valid, UI shows values using AppConfig

### 3.2 Non-Functional Requirements

**NFR-1: Clear failure messaging**
- Missing required values should produce a localized error

**NFR-2: Maintainability**
- Keep demo-specific config types in demo target
- Use simple, obvious naming aligned with PRD terminology

---

## 4. Technical Design

### 4.1 New Demo Types

Location: `Demo/ConfigPetApp/ConfigPetApp/AppConfig.swift`

- `AppConfigDraft` with optional fields
- `AppConfig` with non-optional fields
- `AppConfigError` for missing required values
- `AppConfig.profile` static property with SpecProfile

### 4.2 ConfigManager Changes

- Build AppConfig using ConfigPipeline after loading reader
- Expose `config` and `buildResult` for UI access

### 4.3 ContentView Changes

- Render name/sleeping state from `AppConfig`
- Keep status copy in place for E4 updates

---

## 5. Execution Plan (Checklist)

- [x] Create `AppConfigDraft`, `AppConfig`, and `AppConfigError`
- [x] Define SpecProfile with bindings for pet.name and pet.isSleeping
- [x] Update ConfigManager to build AppConfig via ConfigPipeline
- [x] Update ContentView to read AppConfig values
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 6. Acceptance Criteria

- AppConfig is produced from config.json using SpecProfile bindings
- App shows pet name + sleeping state from AppConfig
- ConfigManager exposes build result for future error UI
- All validation commands pass

---

## 7. Definition of Done

- All checklist items complete
- Code builds/tests/formatting are green
- Task documentation updated with completed checklist
- `DOCS/Workplan.md` marks E3 as complete

**Archived:** 2025-12-18
