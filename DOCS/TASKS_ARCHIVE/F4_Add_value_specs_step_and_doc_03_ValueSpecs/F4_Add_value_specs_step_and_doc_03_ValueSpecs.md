# Task PRD: F4 — Add value specs step + doc (03_ValueSpecs.md)

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F4
**Priority:** Medium
**Effort:** M
**Dependencies:** B4 (Diagnostics), C2 (ConfigPipeline)

---

## 1. Objective

Add value-level validation rules (value specs) to the demo config pipeline and document the step in the tutorial.

**Current State:**
- Demo config loads and builds without value specs
- `03_ValueSpecs.tutorial` is placeholder content

**Target State:**
- Config bindings apply value specs with clear validation errors
- Tutorial explains how to define and test value specs

**Source:** PRD §9 Phase F, Task F4

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Value specs applied to demo bindings (e.g., non-empty name, range constraints)
2. Error presentation flows through existing diagnostics
3. Tutorial content in `Sources/SpecificationConfig/Documentation.docc/Tutorials/03_ValueSpecs.tutorial`

### 2.2 What this task does NOT deliver

- Decision fallback step (F5)
- Watching step (F6)

### 2.3 Success Criteria

- [x] Value specs enforce validation rules and surface diagnostics
- [x] Tutorial covers value specs and expected errors
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Value specs in bindings**
- Add at least one value spec to demo bindings
- Ensure invalid values produce diagnostics

**Acceptance Criteria:**
- Tests show invalid values fail with diagnostics
- Demo app shows error list when value specs fail

**FR-2: Tutorial step**
- Provide step-by-step instructions for adding value specs
- Include an example failing value and expected output

**Acceptance Criteria:**
- Tutorial references demo files and config keys

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- No placeholder text remains
- Instructions are concise and repo-accurate

---

## 4. Execution Plan (Checklist)

- [x] Add tests for value specs (prefer failing test first)
- [x] Add value specs to demo bindings
- [x] Update tutorial `03_ValueSpecs.tutorial`
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- Value specs are applied and validated
- Tutorial content matches current behavior
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
