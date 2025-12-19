# Task PRD: F1 — Write Docs/Tutorial/01_MVP.md matching v0

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F1
**Priority:** High
**Effort:** M
**Dependencies:** E5 (Demo MVP complete)

---

## 1. Objective

Write the MVP tutorial for Config Pet v0 so users can reproduce the current demo app: config.json file, AppConfig types, SpecProfile bindings, and reload flow.

**Current State:**
- `01_MVP.tutorial` is placeholder content
- Demo app and config pipeline exist (E1–E5)

**Target State:**
- Tutorial describes the v0 implementation steps
- Includes key code snippets and file references
- Matches current demo app behavior

**Source:** PRD §9 Phase F, Task F1

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Full tutorial content in `Sources/SpecificationConfig/Documentation.docc/Tutorials/01_MVP.tutorial`
2. Steps covering:
   - config.json creation
   - AppConfigDraft/AppConfig definitions
   - SpecProfile bindings
   - ConfigManager integration
   - UI split view + reload + error panel

### 2.2 What this task does NOT deliver

- Env override step (F3)
- Value specs/decisions/watching steps (F4–F6)
- Additional demo features beyond v0

### 2.3 Success Criteria

- [x] Tutorial content matches current demo app
- [x] Code snippets reflect existing files/paths
- [x] Steps are clear and sequential
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: MVP tutorial steps**
- Provide sequential steps to recreate v0
- Include commands for running the demo

**Acceptance Criteria:**
- Tutorial references `Demo/ConfigPetApp/config.json`
- Tutorial references `AppConfig.swift`, `ConfigManager.swift`, `ContentView.swift`

**FR-2: Accurate code snippets**
- Snippets match the current implementation

**Acceptance Criteria:**
- Snippets compile if applied to a clean repo at v0

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- No placeholder text remains
- Use concise, instructional tone

---

## 4. Execution Plan (Checklist)

- [x] Replace placeholder content in `01_MVP.tutorial`
- [x] Align steps with current demo layout and reload flow
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- Tutorial fully describes MVP setup and usage
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
