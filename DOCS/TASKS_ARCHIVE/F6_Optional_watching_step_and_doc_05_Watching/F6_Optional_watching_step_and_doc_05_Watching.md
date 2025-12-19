# Task PRD: F6 — Optional watching step + doc (05_Watching.md)

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F6
**Priority:** Low
**Effort:** L
**Dependencies:** E2 (config loader)

---

## 1. Objective

Document an optional configuration watching setup using Swift Configuration's reloading providers.

**Current State:**
- `05_Watching.tutorial` is placeholder content
- Demo reloads manually via Reload button

**Target State:**
- Tutorial explains optional automatic reloads using `ReloadingFileProvider`
- Notes the required `Reloading` build flag and service loop

**Source:** PRD §9 Phase F, Task F6

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Tutorial content in `Sources/SpecificationConfig/Documentation.docc/Tutorials/05_Watching.tutorial`
2. Optional guidance on automatic reloading

### 2.2 What this task does NOT deliver

- A fully wired live-reload demo in the app
- Changes to CI or release notes

### 2.3 Success Criteria

- [x] Tutorial explains optional watching with accurate constraints
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Optional watching guide**
- Provide steps for using `ReloadingFileProvider<JSONSnapshot>`
- Call out the need for ServiceLifecycle and the `Reloading` flag

**Acceptance Criteria:**
- Tutorial references demo config file and notes manual Reload fallback

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- No placeholder text remains

---

## 4. Execution Plan (Checklist)

- [x] Update tutorial `05_Watching.tutorial`
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- Tutorial matches current repo behavior
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
