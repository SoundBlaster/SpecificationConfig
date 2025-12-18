# Task PRD: F5 — Add decision fallback step + doc (04_Decisions.md)

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F5
**Priority:** Medium
**Effort:** M
**Dependencies:** C2 (ConfigPipeline)

---

## 1. Objective

Introduce DecisionSpec-based fallback logic in the demo config flow and document how to use it.

**Current State:**
- Demo config uses defaults and value specs only
- `04_Decisions.tutorial` is placeholder content

**Target State:**
- Demo uses DecisionSpec to derive a fallback when config values are missing
- Tutorial explains how decisions work and how to test them

**Source:** PRD §9 Phase F, Task F5

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. DecisionSpec fallback logic in the demo config pipeline
2. Tutorial content in `Sources/SpecificationConfig/Documentation.docc/Tutorials/04_Decisions.tutorial`
3. Tests that demonstrate DecisionSpec fallback behavior

### 2.2 What this task does NOT deliver

- Watching step (F6)
- Release checklist/changelog (G3)

### 2.3 Success Criteria

- [x] DecisionSpec fallback produces a valid config when keys are missing
- [x] Tutorial covers decision fallback with examples
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: DecisionSpec fallback**
- Add DecisionSpec logic to compute a fallback value
- Prefer explicit config values when present

**Acceptance Criteria:**
- Tests cover fallback and precedence
- Demo shows derived value when config is missing

**FR-2: Tutorial step**
- Provide step-by-step instructions and example values

**Acceptance Criteria:**
- Tutorial references demo files and expected UI behavior

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- No placeholder text remains
- Instructions are concise and repo-accurate

---

## 4. Execution Plan (Checklist)

- [x] Add tests for DecisionSpec fallback (prefer failing test first)
- [x] Implement DecisionSpec fallback in demo config
- [x] Update tutorial `04_Decisions.tutorial`
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- DecisionSpec fallback applied and validated
- Tutorial content matches current behavior
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
