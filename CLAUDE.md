# SpecificationConfig: Quickstart for Claude

- **Scope:** Applies to the whole repo. Follow `AGENTS.md` plus these Claude-specific cues.
- **Purpose:** Give you the mental map of `DOCS/` so you can find workflows and rules fast.

## DOCS Map
- `DOCS/PRD/SpecificationConfig_PRD.md` — single source of product requirements and task IDs (A1…G3).
- `DOCS/COMMANDS/` — workflow prompts:
  - `SELECT` → pick the next task
  - `PLAN` → turn it into an implementation-ready PRD
  - `EXECUTE` → pre-flight, implement, validate, finalize
  - `PROGRESS` → optional status updates
  - `ARCHIVE` → retire completed task PRDs
  - `README.md` → overview and validation baseline
- `DOCS/RULES/` — standards/templates:
  - `01_PRD_PROMPT.md` → how to write PRDs for this repo (include validation commands)
  - `03_XP_TDD_Workflow.md` → outside-in, test-first, always-green guidance
  - `COMMAND_TEMPLATE.md` → pattern for new command specs
  - `01_Swift_Install.md` → environment setup notes
- `DOCS/INPROGRESS/`, `DOCS/TASKS_ARCHIVE/` — live vs. archived task PRDs.
- `DOCS/Workplan.md` — **required** checklist of PRD task IDs.

## Usage Principles
- Treat command files as instructions/prompts, not shell scripts.
- Default loop: `SELECT → PLAN → EXECUTE`, with `ARCHIVE` periodically; use `PROGRESS` when you need status breadcrumbs.
- Run at least `swift build -v` and `swift test -v` (plus `swiftformat --lint .` if available) before calling work done.
- Name new task docs with PRD IDs when possible (A1…G3) and keep the DOCS map above in sync if you add structure.
