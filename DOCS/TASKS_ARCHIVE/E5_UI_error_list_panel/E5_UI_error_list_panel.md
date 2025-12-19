# Task PRD: E5 — UI error list panel when build fails

**Version:** 1.0.0
**Status:** Complete
**Task ID:** E5
**Priority:** High
**Effort:** M
**Dependencies:** B4 (Diagnostics), C2 (ConfigPipeline)

---

## 1. Objective

Expose configuration build diagnostics in the ConfigPetApp UI when the build fails, so users can see which keys failed and why.

**Current State:**
- UI shows AppConfig values on success
- Failures only surface as a status string
- Diagnostics are not visible in the UI

**Target State:**
- Error list panel appears when ConfigPipeline returns a failure
- Each diagnostic shows severity, key, and message
- Panel lives alongside existing config status/values

**Source:** PRD §9 Phase E, Task E5

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Error list panel in ContentView
2. Rendering of diagnostics from BuildResult failure
3. Basic severity styling for readability

### 2.2 What this task does NOT deliver

- Split view layout changes (already done in E4)
- Additional diagnostics generation logic (handled in pipeline)
- Advanced UX/animations

### 2.3 Success Criteria

- [x] Error list appears when build fails
- [x] Each diagnostic shows key + message
- [x] Errors are visually distinct from warnings/info
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Error panel rendering**
- When BuildResult is failure, render a list of diagnostics
- Use DiagnosticsReport.diagnostics ordering

**Acceptance Criteria:**
- List items include key (or "General") and formatted message

**FR-2: Severity styling**
- Map severity to color (error/red, warning/orange, info/blue/secondary)

**Acceptance Criteria:**
- Errors are easily distinguishable from warnings/info

### 3.2 Non-Functional Requirements

**NFR-1: Maintainability**
- Changes localized to demo UI
- No new dependencies

---

## 4. Technical Design

### 4.1 ContentView Changes

- Add diagnostics section in left panel
- Use BuildResult failure to source diagnostics
- Render with `ForEach` using stable IDs

---

## 5. Execution Plan (Checklist)

- [x] Add diagnostics section to ContentView
- [x] Render diagnostics from BuildResult failure
- [x] Add severity color mapping
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 6. Acceptance Criteria

- Error panel displays when config build fails
- Diagnostics show key + message and severity styling
- Validation commands pass

---

## 7. Definition of Done

- All checklist items complete
- Task documentation updated with completed checklist
- `DOCS/Workplan.md` marks E5 as complete

**Archived:** 2025-12-19
