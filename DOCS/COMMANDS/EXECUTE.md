# EXECUTE — Implement And Validate Current Task

**Version:** 1.0.0

## Purpose

Provide a thin, repeatable workflow wrapper for implementing a selected task in this repository:

1. Pre-flight checks (verify and setup tooling + git state)
2. Implement work (following a task PRD or PRD §9)
3. Validate like CI
4. Finalize documentation and optionally commit

EXECUTE does not “auto-implement” requirements; it only standardizes the loop around implementation.

## Inputs (Preferred)

- `DOCS/INPROGRESS/next.md` (optional) — the selected task
- `DOCS/INPROGRESS/{ID}_{Title}.md` (optional) — task PRD created by PLAN
- `DOCS/PRD/SpecificationConfig_PRD.md` — canonical requirements, work plan, acceptance criteria
- `.github/workflows/ci.yml` — canonical validation commands

## Pre-Flight Checks

1. Confirm Swift is available:
   - `swift --version`
1.1 If not available: download and install - see DOCS/RULES/01_Swift_Install.md
2. Confirm a clean working tree (recommended):
   - `git status --porcelain`
3. Confirm the selected task is known:
   - If using `DOCS/INPROGRESS/next.md`, ensure it names a task ID from PRD §9.

## Work Period

Implement the selected task by following (in order of preference):

1. The task PRD in `DOCS/INPROGRESS/{ID}_{Title}.md` (if it exists)
2. Otherwise, the corresponding task row in PRD §9 plus the acceptance test plan in PRD §10

Follow the workflow rules in `DOCS/RULES/03_XP_TDD_Workflow.md`.

## Post-Flight Validation (Match CI)

Run the same checks CI uses:

```bash
swift build -v
swift test -v
```

If you have SwiftFormat installed (CI does), run:

```bash
swiftformat --lint .
```

Optional (CI runs this on macOS):

```bash
swift test --sanitize=thread
```

## Finalization

1. Update documentation (optional but recommended):
   - Mark the task PRD checklist items complete.
   - Update `DOCS/INPROGRESS/next.md` status.
   - If you maintain `DOCS/Workplan.md`, mark the task `[x]`.
2. Commit and push as appropriate for your workflow.

## Exceptions

- Swift not available → install it first (see `DOCS/RULES/01_Swift_Install.md`).
- Validation fails → fix issues and re-run the post-flight commands until green.
