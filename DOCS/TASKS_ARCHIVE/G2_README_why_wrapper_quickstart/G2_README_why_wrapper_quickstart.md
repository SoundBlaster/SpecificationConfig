# Task PRD: G2 — README “Why this wrapper” + quickstart

**Version:** 1.0.0
**Status:** Complete
**Task ID:** G2
**Priority:** High
**Effort:** M
**Dependencies:** F1 (MVP tutorial)

---

## 1. Objective

Rewrite the README to explain why the wrapper exists and provide a clear quickstart aligned with the current API and demo app.

**Current State:**
- README describes a placeholder scaffold
- Missing value proposition and quickstart

**Target State:**
- README includes "Why this wrapper" section
- Quickstart shows how to define bindings and build config
- Demo app instructions are accurate

**Source:** PRD §9 Phase G, Task G2

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Updated README with value proposition
2. Quickstart with current API usage
3. Demo app instructions

### 2.2 What this task does NOT deliver

- Release notes (G3)
- Additional tutorial content beyond F1

### 2.3 Success Criteria

- [x] README explains why the wrapper exists
- [x] Quickstart compiles against current API
- [x] Demo instructions match current project setup
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Why this wrapper**
- Explain explicit injection, type safety, and deterministic diagnostics

**Acceptance Criteria:**
- README calls out Swift Configuration + SpecificationCore integration

**FR-2: Quickstart**
- Show minimal bindings + profile + pipeline build

**Acceptance Criteria:**
- Snippet references `Binding`, `AnyBinding`, `SpecProfile`, `ConfigPipeline`

**FR-3: Demo app instructions**
- Point to `Demo/ConfigPetApp` and Tuist steps

**Acceptance Criteria:**
- Commands and paths are accurate

---

## 4. Execution Plan (Checklist)

- [x] Update README “Why this wrapper” section
- [x] Add Quickstart with minimal code
- [x] Update demo instructions
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Definition of Done

- README updated and verified
- Workplan updated and task archived

**Archived:** 2025-12-19
