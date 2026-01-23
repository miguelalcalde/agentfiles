---
description: Pick the next task from the backlog and create a blank PRD
---

Use the **picker** agent to select the next high-priority task from the backlog.

## Instructions

1. Read `docs/backlog.md` to find pending tasks
2. Select the highest priority task that is still `pending`
3. Create a blank PRD using the template at `.claude/skills/feature-workflow/templates/prd-template.md`
4. Save the PRD to `docs/prds/[FEAT-ID].md`
5. Update the backlog to mark the task as `prd_created`

## Selection Criteria

Default: Select the highest priority pending task (P0 > P1 > P2).

If the user specifies criteria (e.g., "pick a P1 task"), use that instead.

## Output

Report:
- Which task was selected and why
- Path to the created PRD
- Next steps for the user
