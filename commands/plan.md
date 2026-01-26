---
description: Create an implementation plan from an approved PRD
arguments:
  - name: slug
    description: The feature slug to plan (e.g., user-auth)
    required: true
---

Use the **planner** agent to create an implementation plan for $ARGUMENTS.slug.

## Instructions

1. Read the PRD at `docs/prds/PRD-$ARGUMENTS.slug.md`
2. Verify the PRD status is `approved` (warn if not, but continue if user confirms)
3. Deep-dive into the codebase to:
   - Identify files to create/modify
   - Understand existing patterns and conventions
   - Map dependencies between changes
4. Create the implementation plan using template at `skills/feature-workflow/templates/plan-template.md`
5. Save the plan to `docs/plans/PLAN-$ARGUMENTS.slug.md`
6. Update the PRD frontmatter to link to the plan

## Task Requirements

Each task must include:

- Clear description of what to do
- Specific file paths (existing or to be created)
- Dependencies on other tasks
- Estimated complexity (Low/Medium/High)
- Testing requirements

## Task Ordering

1. Foundation/infrastructure changes first
2. Core functionality second
3. UI/integration third
4. Tests alongside each phase
5. Documentation last

## Output

Report:

- Summary of the implementation approach
- Total number of tasks and estimated complexity
- Branch name: `feat/$ARGUMENTS.slug`
- Any risks identified
- Next steps (human review before implementation)
