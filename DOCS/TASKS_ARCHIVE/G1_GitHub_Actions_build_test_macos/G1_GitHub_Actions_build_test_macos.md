# Task PRD: G1 — GitHub Actions: build + test on macOS

**Version:** 1.0.0
**Status:** Complete
**Task ID:** G1
**Priority:** High
**Effort:** S
**Dependencies:** C2 (ConfigPipeline)

---

## 1. Objective

Ensure CI runs `swift build -v` and `swift test -v` on macOS so the core package is validated on Apple tooling.

**Current State:**
- A CI workflow exists but must be verified against the PRD requirements

**Target State:**
- GitHub Actions workflow runs build and tests on macOS
- Validation commands match PRD §12 and CI expectations

**Source:** PRD §9 Phase G, Task G1

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Verified macOS CI job that runs build + tests
2. Optional SwiftFormat lint if available

### 2.2 What this task does NOT deliver

- README updates (G2)
- Release checklist (G3)

### 2.3 Success Criteria

- [x] CI workflow includes macOS build + test steps
- [x] `swift build -v` and `swift test -v` run successfully locally

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: macOS CI job**
- Workflow runs on macOS runners
- Executes `swift build -v` and `swift test -v`

**Acceptance Criteria:**
- Workflow file includes a macOS job with build + test steps

---

## 4. Execution Plan (Checklist)

- [x] Inspect `.github/workflows/ci.yml`
- [x] Add or adjust macOS job to run build + test
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Definition of Done

- CI workflow is aligned to PRD requirements
- Workplan updated and task archived

**Archived:** 2025-12-19
