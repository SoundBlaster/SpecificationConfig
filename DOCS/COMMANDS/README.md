# SpecificationConfig Workflow Commands

**Version:** 2.1.0

## Overview

These command specs describe a lightweight, documentation-driven workflow for this repository. They are meant to be used
as **prompts/instructions for a coding agent** (or a human), not as executable shell scripts.

| Command | Purpose | Details |
|---------|---------|---------|
| **SELECT** | Choose the next work item | [SELECT.md](./SELECT.md) |
| **PLAN** | Turn the selected item into an implementation-ready task PRD | [PLAN.md](./PLAN.md) |
| **EXECUTE** | Pre-flight → implement → validate → finalize | [EXECUTE.md](./EXECUTE.md) |
| **PROGRESS** | Optional checklist/progress updates | [PROGRESS.md](./PROGRESS.md) |
| **ARCHIVE** | Move completed task PRDs out of the way | [ARCHIVE.md](./ARCHIVE.md) |

## Source Of Truth

- Product/design requirements: `DOCS/PRD/SpecificationConfig_PRD.md`
- Repository reality (what you can actually run): `Package.swift`, `.github/workflows/ci.yml`

## Bootstrap (If You Adopt This Workflow)

This repo currently ships only the PRD above. If you want the full “SELECT → PLAN → EXECUTE” loop, create:

```bash
mkdir -p DOCS/INPROGRESS DOCS/TASKS_ARCHIVE
touch DOCS/INPROGRESS/next.md
```

Optionally add `DOCS/Workplan.md` by extracting task IDs from PRD §9 (A1…G3) into a checkbox list.

## Workflow

```
SELECT → PLAN → EXECUTE → (repeat)
                     ↓
                 ARCHIVE (periodically)
```

**Philosophy:** implementation instructions live in task PRDs derived from `DOCS/PRD/SpecificationConfig_PRD.md`. These
commands standardize selection, planning, validation, and documentation updates.

## Validation Baseline

At minimum, match CI locally:

```bash
swift build -v
swift test -v
```

If you have SwiftFormat installed (CI does), also run:

```bash
swiftformat --lint .
```

## Repository Files (Current)

```
DOCS/
  COMMANDS/
  PRD/
    SpecificationConfig_PRD.md
  RULES/
.github/workflows/ci.yml
Package.swift
Sources/SpecificationConfig/
Tests/SpecificationConfigTests/
```
