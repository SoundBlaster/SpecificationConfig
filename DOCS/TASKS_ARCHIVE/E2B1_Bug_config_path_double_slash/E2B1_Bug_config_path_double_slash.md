# Task PRD: E2B1 — Bug: config path shows double slash in error

**Version:** 1.0.0
**Status:** Complete
**Task ID:** E2B1
**Priority:** Medium
**Effort:** S
**Dependencies:** E2 (Config file loader)

---

## 1. Objective

Record and scope the bug where the ConfigPetApp shows a double-slash path in the missing config error message.

**Current State:**
- Error message displayed: "Error: Configuration file not found at: // config.json"

**Target State:**
- Bug is documented and ready for implementation planning

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Bug record scoped to the config file loader path generation

### 2.2 What this task does NOT deliver

- A code fix (handled in a follow-up execution task)

### 2.3 Success Criteria

- [x] Bug is documented with reproduction and expected behavior
- [x] Task is listed in `DOCS/Workplan.md`

---

## 3. Bug Details

**Title:** Config file not found error shows double slash path

**Observed:**
- UI shows: "Error: Configuration file not found at: // config.json"

**Expected:**
- UI shows a normalized path (no double slash), e.g. ".../config.json"

**Likely Area:**
- `Demo/ConfigPetApp/ConfigPetApp/ConfigFileLoader.swift` default path composition

---

## 4. Execution Plan (Checklist)

- [x] Add bug task entry to `DOCS/Workplan.md`
- [x] Confirm task PRD includes repro + expected behavior

---

## 5. Definition of Done

- Bug task recorded and linked to E2

## 6. Resolution

- Fixed by normalizing config paths with URL-based joining in `ConfigFileLoader`
- Added unit tests covering path normalization

**Archived:** 2025-12-19
