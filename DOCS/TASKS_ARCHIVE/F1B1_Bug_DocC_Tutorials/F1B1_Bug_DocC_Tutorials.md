# Task PRD: F1B1 — Bugs in DocC tutorials (highlighting, examples, entry link)

**Version:** 1.0.0  
**Status:** Complete  
**Task ID:** F1B1  
**Priority:** Medium  
**Effort:** S  
**Dependencies:** F1 (MVP tutorial content)

---

## 1. Objective

Record and scope the DocC tutorial documentation issues reported for the tutorials set.

**Current State:**
- Tutorial output includes at least one code block that renders without syntax highlighting.
- At least one tutorial page has no code examples.
- The tutorial map link in the main DocC landing page does not resolve.

**Target State:**
- Bugs are documented with repro notes, expected behavior, and likely locations.
- Workplan includes a tracking entry.

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. A scoped bug record for DocC tutorials highlighting/examples/link issues.

### 2.2 What this task does NOT deliver

- Any DocC content fixes (handled in a follow-up execution task).

### 2.3 Success Criteria

- [x] Bugs are documented with reproduction + expected behavior.
- [x] Task is listed in `DOCS/Workplan.md`.

---

## 3. Bug Details

### 3.1 Missing syntax highlighting in a tutorial code block

**Observed:**
- At least one `@Code` snippet renders as plain text (no Swift syntax highlighting) in the DocC tutorial output.

**Expected:**
- All `@Code` snippets render with Swift syntax highlighting.

**Likely Area:**
- DocC tutorial pages under `Sources/SpecificationConfig/Documentation.docc/Tutorials/` (exact snippet TBD; verify during DocC build/preview).

---

### 3.2 Tutorial page missing code examples

**Observed:**
- `Sources/SpecificationConfig/Documentation.docc/Tutorials/00_Intro.tutorial` contains no `@Code` examples.

**Expected:**
- Each tutorial page includes at least one code example, or the intro page is explicitly structured as a non-code primer.

**Likely Area:**
- `Sources/SpecificationConfig/Documentation.docc/Tutorials/00_Intro.tutorial`

---

### 3.3 Broken tutorial map entry link

**Observed:**
- The tutorial map link in the DocC landing page does not resolve:
  - `Sources/SpecificationConfig/Documentation.docc/SpecificationConfig.md` → `<doc:Tutorials>`

**Expected:**
- `<doc:Tutorials>` navigates to the tutorial map entry point (`Tutorials.tutorial`).

**Likely Area:**
- `Sources/SpecificationConfig/Documentation.docc/SpecificationConfig.md`
- `Sources/SpecificationConfig/Documentation.docc/Tutorials/Tutorials.tutorial` (identifier resolution)

---

## 4. Execution Plan (Checklist)

- [x] Add bug task entry to `DOCS/Workplan.md`.
- [x] Confirm the PRD captures repro + expected behavior for each item.

---

## 5. Definition of Done

- Bug task recorded with clear locations and expectations.
- Workplan updated with F1B1 entry.

**Archived:** 2026-01-26
