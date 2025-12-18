# Task PRD: F2 — Tag repo tutorial-v0

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F2
**Priority:** High
**Effort:** S
**Dependencies:** F1 (MVP tutorial content)

---

## 1. Objective

Create the `tutorial-v0` git tag that marks the repository state matching the MVP tutorial.

**Current State:**
- MVP tutorial content is written
- No `tutorial-v0` tag exists

**Target State:**
- Git tag `tutorial-v0` points to the commit that contains the v0 tutorial

**Source:** PRD §9 Phase F, Task F2

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. A git tag `tutorial-v0` applied to the correct commit

### 2.2 What this task does NOT deliver

- New code or documentation changes
- Any additional tutorial content

### 2.3 Success Criteria

- [x] Repository has a `tutorial-v0` tag
- [x] Tag points at the commit with MVP tutorial content

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Create tag**
- Tag name: `tutorial-v0`

**Acceptance Criteria:**
- `git tag -l tutorial-v0` returns the tag

---

## 4. Execution Plan (Checklist)

- [x] Ensure MVP tutorial commit is created
- [x] Create `tutorial-v0` tag
- [x] Verify tag exists

---

## 5. Acceptance Criteria

- Tag exists and points to correct commit

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
