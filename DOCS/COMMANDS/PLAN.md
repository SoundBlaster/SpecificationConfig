# PLAN — Generate Task PRD

**Version:** 1.0.0

## Purpose

Turn a selected task (usually from PRD §9) into an **implementation-ready, single-task PRD** with concrete steps and
verification commands that match the current repository.

## Inputs

- Selection: `DOCS/INPROGRESS/next.md` (preferred) or an explicit task ID (e.g., `B2`)
- Rules: `DOCS/RULES/01_PRD_PROMPT.md`
- Canonical project PRD: `DOCS/PRD/SpecificationConfig_PRD.md`
- Optional tracking: `DOCS/Workplan.md` (if you use it)

## Algorithm

1. Determine the task ID + title:
   - Parse `DOCS/INPROGRESS/next.md`, or accept an explicit ID passed in the prompt.
2. Pull task row details from `DOCS/PRD/SpecificationConfig_PRD.md` §9 (priority, effort, deps, expected outputs).
3. Translate the row into an execution-ready plan:
   - Concrete file paths under `Sources/` and `Tests/`
   - Explicit API surface touched (types/functions/modules)
   - Verification commands that exist in this repo (see `.github/workflows/ci.yml`)
4. Emit `DOCS/INPROGRESS/{ID}_{Title}.md` using the structure rules from `DOCS/RULES/01_PRD_PROMPT.md`, plus:
   - A checklist of subtasks
   - Acceptance criteria per subtask
   - Final “Definition of done” aligned to PRD §12

## Output

- `DOCS/INPROGRESS/{ID}_{Title}.md`

## Exceptions

- Missing selection and no explicit ID → stop and ask for a task ID.
- Task ID not found in PRD §9 → stop and ask to confirm the ID.
- Output PRD already exists → require an explicit overwrite decision.
