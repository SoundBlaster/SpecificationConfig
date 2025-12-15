# SELECT Command Algorithm (Hypercode)
# Version: 2.0.0
# Purpose: Select the next work item for SpecificationConfig from PRD §9 (or Workplan.md if present).

"SELECT — Next Work Item"
    "Version: 2.0.0"

    "Purpose"
        "Choose the next task for SpecificationConfig."
        "Record a minimal selection in DOCS/INPROGRESS/next.md."
        "Do NOT generate implementation steps (PLAN does that)."

    "Inputs (preferred order)"
        "DOCS/Workplan.md (optional)"
            "Checkbox list derived from DOCS/PRD/SpecificationConfig_PRD.md §9."
        "DOCS/PRD/SpecificationConfig_PRD.md"
            "Canonical tasks (A1…G3) and dependencies."
        "DOCS/INPROGRESS/next.md (optional)"
            "Current selection state."

    "Algorithm"
        "Step 1: Build candidate set"
            "If Workplan exists: take unchecked tasks."
            "Else: take tasks from PRD §9 tables."
        "Step 2: Filter by dependencies (if known)"
            "If dependencies are tracked, exclude tasks whose deps are not complete."
            "If dependencies are unknown, allow selection but record Unknown."
        "Step 3: Rank candidates"
            "Prefer Priority: High > Medium > Low."
            "Prefer earlier Phase: A → G."
            "Prefer smaller numeric ID."
        "Step 4: Emit next.md"
            "Write minimal metadata: ID, title, source=PRD, priority, phase, effort, dependencies."
            "No checklists, no acceptance criteria, no templates."
        "Step 5: Update Workplan (optional)"
            "If Workplan exists, mark selected task INPROGRESS."

    "Outputs"
        "DOCS/INPROGRESS/next.md"
        "DOCS/Workplan.md (optional update)"

    "Error Handling"
        "No candidates"
            "Stop with message: nothing to do."
        "Missing inputs"
            "If neither Workplan nor PRD is available, stop and ask for task list."
