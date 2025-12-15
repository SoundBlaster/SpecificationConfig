# ARCHIVE — Archive Completed Task PRDs

**Version:** 2.1.0

## Purpose

If you are using the optional `DOCS/INPROGRESS/` task-PRD workflow, ARCHIVE moves completed task PRDs out of the active
folder into `DOCS/TASKS_ARCHIVE/` to keep the workspace tidy.

If you are not using `DOCS/INPROGRESS/`, this command is a no-op.

## Inputs

- `DOCS/INPROGRESS/*.md` (optional) — task PRDs
- `DOCS/TASKS_ARCHIVE/` (optional) — archive destination
- `DOCS/Workplan.md` (optional) — completion state, if you track it

## Algorithm

1. Determine which task PRDs are “completed”:
   - If `DOCS/Workplan.md` exists: completed = task marked `[x]`.
   - Otherwise: completed = task PRD explicitly marked “Completed” in its own header.
2. For each completed task PRD:
   - Move it from `DOCS/INPROGRESS/` to `DOCS/TASKS_ARCHIVE/`.
   - Append an archive stamp at the end: `**Archived:** YYYY-MM-DD`.
3. Update/create `DOCS/TASKS_ARCHIVE/INDEX.md` with a simple list grouped by PRD Phase (A…G) if known.

## Output

- Updated `DOCS/TASKS_ARCHIVE/` contents (+ `INDEX.md`)

## Notes

- Do not automatically push. If you want archival recorded, commit normally after verifying changes.
