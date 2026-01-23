---
description: Refine a PRD to ensure it's complete and ready for planning
arguments:
  - name: feat_id
    description: The feature ID to refine (e.g., FEAT-001)
    required: true
---

Use the **refiner** agent to complete and validate the PRD for $ARGUMENTS.feat_id.

## Instructions

1. Read the PRD at `docs/prds/$ARGUMENTS.feat_id.md`
2. Review against the template at `.claude/skills/feature-workflow/templates/prd-template.md`
3. Research the codebase to understand:
   - Current architecture and patterns
   - Related existing functionality
   - Technical constraints
4. Fill in all missing sections with detailed, actionable content
5. Update the PRD frontmatter with:
   - `status: refined`
   - `refined_at: [current timestamp]`
   - `refined_by: agent:refiner`
   - Increment `iterations`
6. Save the updated PRD

## Quality Checklist

Ensure:
- [ ] Problem statement is clear and specific
- [ ] Proposed solution is technically feasible
- [ ] Acceptance criteria are testable
- [ ] Dependencies are identified
- [ ] Out of scope is defined

## Output

Report:
- Summary of changes made
- Quality score assessment
- Any open questions that need human input
- Next steps (human review before planning)
