# Repository Navigation and Workflow Guardrails

This file applies to the entire repository.

## DOCS Layout (Quick Map)
- `DOCS/PRD/` — canonical product requirements (see `SpecificationConfig_PRD.md`).
- `DOCS/COMMANDS/` — workflow prompts for agents/humans:
  - `SELECT.md` → choose next work item
  - `PLAN.md` → turn selection into an implementation-ready task PRD
  - `EXECUTE.md` → pre-flight → implement → validate → finalize
  - `PROGRESS.md` → optional status checklist
  - `ARCHIVE.md` → move completed task PRDs
  - `README.md` → overview of the command set and validation baseline
- `DOCS/RULES/` — supporting standards and templates (e.g., PRD authoring rules, XP/TDD workflow, command template, Swift install notes).
- `DOCS/INPROGRESS/` and `DOCS/TASKS_ARCHIVE/` — active and archived task PRDs.
- `DOCS/Workplan.md` — **required** task checklist derived from PRD IDs.

## How to Use the Commands
- Treat files in `DOCS/COMMANDS/` as prompts/instructions, not shell scripts.
- Default workflow: `SELECT → PLAN → EXECUTE`, with periodic `ARCHIVE`; use `PROGRESS` for status updates.
- Validate changes at least with `swift build -v` and `swift test -v`; run `swiftformat --lint .` if available.
- When authoring or updating command specs, keep versions and purpose sections aligned with the templates in `DOCS/COMMANDS`.

## Supporting Rules
- Follow `DOCS/RULES/01_PRD_PROMPT.md` when writing PRDs: precise scope, hierarchical TODOs, acceptance criteria, and repo-aware verification commands.
- Apply the XP-inspired TDD guidance in `DOCS/RULES/03_XP_TDD_Workflow.md`: outside-in, test-first, always-green main, refactor with tests.
- Use `DOCS/RULES/COMMAND_TEMPLATE.md` as the pattern for new command specs.
- Check `DOCS/RULES/01_Swift_Install.md` for environment setup notes when needed.

## General Expectations
- Keep repository structure consistent with the DOCS map above.
- Reference PRD §9 task IDs (A1…G3) for naming/organizing task files when applicable.
- If you add files under `DOCS/`, ensure they are reflected appropriately in this structure summary.
