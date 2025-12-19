# Task PRD: G3 — 0.1.0 release checklist + changelog

**Version:** 1.0.0
**Status:** Complete
**Task ID:** G3
**Priority:** Medium
**Effort:** S
**Dependencies:** G1 (CI), G2 (README)

---

## 1. Objective

Create a 0.1.0 release checklist and initial changelog for SpecificationConfig.

**Current State:**
- No release checklist in repo
- No changelog file

**Target State:**
- Release checklist exists with concrete steps
- `CHANGELOG.md` has a 0.1.0 entry

**Source:** PRD §9 Phase G, Task G3

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Release checklist document (repo root)
2. `CHANGELOG.md` with 0.1.0 notes

### 2.2 What this task does NOT deliver

- A published Git tag or GitHub release
- CI changes beyond G1

### 2.3 Success Criteria

- [x] Checklist covers build, test, tagging, and release notes
- [x] Changelog summarizes 0.1.0 scope
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Release checklist**
- Provide step-by-step release process
- Include references to CI validation commands

**Acceptance Criteria:**
- Checklist is actionable and repo-specific

**FR-2: Changelog**
- Add 0.1.0 section with key features

**Acceptance Criteria:**
- Changelog uses consistent format and dates

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- Use concise bullet points
- Keep content in ASCII

---

## 4. Execution Plan (Checklist)

- [x] Add `RELEASE_CHECKLIST.md`
- [x] Add `CHANGELOG.md`
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- Release checklist and changelog exist and match repo state
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
