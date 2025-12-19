# Task PRD: F3 — Add ENV override step + doc (02_EnvOverrides.md)

**Version:** 1.0.0
**Status:** Complete
**Task ID:** F3
**Priority:** Medium
**Effort:** M
**Dependencies:** D1 (helpers), E2 (config loader)

---

## 1. Objective

Add environment variable overrides to the config loading pipeline and document the new behavior in the tutorial step.

**Current State:**
- `ConfigFileLoader` loads only from config.json (bundle + working dir)
- `02_EnvOverrides.tutorial` is placeholder content

**Target State:**
- Config values can be overridden via environment variables
- Tutorial step explains how to set env vars and verify overrides

**Source:** PRD §9 Phase F, Task F3

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Environment variable override support wired into `ConfigFileLoader`
2. Tutorial content in `Sources/SpecificationConfig/Documentation.docc/Tutorials/02_EnvOverrides.tutorial`
3. Tests demonstrating env overrides (TDD-first where feasible)

### 2.2 What this task does NOT deliver

- Value specs/decisions/watching steps (F4–F6)
- New demo UI features beyond environment overrides

### 2.3 Success Criteria

- [x] Env variables override config.json values in demo and tests
- [x] Tutorial covers env override usage and expected precedence
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Environment variable provider**
- Integrate `EnvironmentVariablesProvider` into the config reader pipeline
- Ensure env vars take precedence over config.json

**Acceptance Criteria:**
- Tests show env var value wins over file value for the same key
- Demo app loads overridden values when env vars are set

**FR-2: Tutorial step**
- Provide step-by-step instructions for using env overrides
- Include examples of env variable naming and precedence

**Acceptance Criteria:**
- Tutorial references demo config keys and shows a working example

### 3.2 Non-Functional Requirements

**NFR-1: Clarity**
- No placeholder text remains
- Instructions are concise and repo-accurate

---

## 4. Execution Plan (Checklist)

- [x] Add tests for env overrides (prefer failing test first)
- [x] Update `ConfigFileLoader` to include `EnvironmentVariablesProvider`
- [x] Update tutorial `02_EnvOverrides.tutorial`
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 5. Acceptance Criteria

- Env overrides are applied and verified via tests
- Tutorial content matches current behavior
- Validation commands pass

---

## 6. Definition of Done

- Checklist complete
- Task archived
- Workplan updated

**Archived:** 2025-12-19
