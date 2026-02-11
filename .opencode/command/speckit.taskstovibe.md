---
description: Convert existing tasks into vibe-kanban tasks for the feature based on available design artifacts.
tools: ['vibe_kanban_list_projects', 'vibe_kanban_create_task']
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. **Setup**: Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list.
2. **Project Selection**:
   - Call `vibe_kanban_list_projects`.
   - Find the project with a name matching the current repository directory name (e.g., `kubernetes-lab`).
   - If multiple matches or no matches, prompt user for selection.
3. **Load Tasks**: Read `tasks.md` from FEATURE_DIR.
4. **Task Creation**:
   - Parse each task from the `tasks.md` checklist format.
   - Extract the Spec ID from the `FEATURE_DIR` name (e.g., `008` from `008-lab-governance`).
   - For each task, call `vibe_kanban_create_task` with:
     - `project_id`: The identified project ID.
     - `title`: Standardized format: `Spec {Spec_ID}: {Priority}/{Story} {Description}`.
       - **Example**: `Spec 008: P1/US1 Implement Sync Logic`
       - If Priority or Story is missing, omit those parts (e.g., `Spec 008: Setup Project Structure`).
     - `description`: Full task line including TaskID, labels, and file paths.
5. **Report**: Output the number of tasks created and the link to the Kanban board if available.
