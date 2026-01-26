---
description: Pick the next task from the backlog and create a blank PRD
---

Use the **picker** agent to select the next high-priority task from the backlog.

## Instructions

1. Read `docs/backlog.md` to find pending tasks
2. Select the highest priority task that is still `pending`
3. Derive a slug from the feature name (lowercase kebab-case, max 30 chars)
4. Create a blank PRD using the template at `skills/feature-workflow/templates/prd-template.md`
5. Save the PRD to `docs/prds/PRD-[slug].md` (e.g., `docs/prds/PRD-user-auth.md`)
6. Update the backlog to mark the task as `prd_created`

## Selection Criteria

Default: Select the highest priority pending task (P0 > P1 > P2).

If the user specifies criteria (e.g., "pick a P1 task"), use that instead.

## Output

Report:

- Which task was selected and why
- The derived slug
- Path to the created PRD
- Next steps for the user
