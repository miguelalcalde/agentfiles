---
description: Implement a feature from an approved plan
arguments:
  - name: feat_id
    description: The feature ID to implement (e.g., FEAT-001)
    required: true
---

Use the **implementer** agent to execute the plan for $ARGUMENTS.feat_id.

## Pre-flight Checks

Before starting:
1. Verify the plan at `docs/plans/$ARGUMENTS.feat_id.md` has status `approved`
2. Check current git branch
3. If not on `feature/$ARGUMENTS.feat_id`, create/checkout the branch

## Instructions

1. Read the implementation plan at `docs/plans/$ARGUMENTS.feat_id.md`
2. For each task in order:
   a. Implement the change
   b. Run linting if available
   c. Run relevant tests if they exist
   d. Commit with message: `feat($ARGUMENTS.feat_id): [task description]`
   e. Update the plan, marking task as complete
3. After all tasks:
   a. Run full test suite
   b. Update plan status to `implemented`
   c. Push branch: `git push -u origin HEAD`

## Commit Convention

```
feat(FEAT-XXX): Brief description

- Detail 1
- Detail 2

Task: [task number from plan]
```

## Error Handling

If a task fails:
1. Document the error in the plan under the task
2. Set task status to `blocked` with reason
3. Continue to next task if independent
4. Stop and report if blocking

## Output

Report:
- Tasks completed vs blocked
- Branch name
- Any issues encountered
- Next steps (human creates PR)

## Rules

- NEVER work on main branch
- NEVER create PRs automatically
- NEVER force push
- Commit after each logical unit of work
