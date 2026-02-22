---
name: plan
description: |
  Create a detailed implementation plan from a PRD.
  Use when turning a refined PRD into actionable, ordered tasks with file paths and dependencies.
disable-model-invocation: true
---

# Planning Methodology

Create a detailed, actionable implementation plan from a PRD.

## Inputs

- **PRD path**: `.backlog/prds/PRD-[slug].md` (or a custom location provided by the user)
- **Plan template**: `skills/backlog/templates/plan-template.md`

## Process

1. **Read the PRD** and verify its status (proceed if not `approved`, but document assumptions and uncertainty)
2. **Deep-dive into the codebase**:
   - Identify files to create or modify
   - Understand existing patterns and conventions
   - Map dependencies between changes
3. **Create the plan** using the template
4. **Save** to `.backlog/plans/PLAN-[slug].md`
5. **Update PRD frontmatter** to link to the plan

## Task Requirements

Each task in the plan MUST include:

- **Clear description** of what to do
- **Specific file paths** (existing or to be created)
- **Dependencies** on other tasks (if any)
- **Estimated complexity** (Low / Medium / High)
- **Testing requirements**

Be specific — no vague tasks like "implement the feature". Every task should be completable in 1–2 hours. Include exact file paths and function names where possible. Consider edge cases and error handling.

## Task Ordering

1. Foundation / infrastructure changes first
2. Core functionality second
3. UI / integration third
4. Tests alongside each phase
5. Documentation last

## Branch Naming

Derive the branch name from the slug:

- **Format**: `feat/[slug]`
- **Example**: slug `user-auth` → branch `feat/user-auth`

Set this in the plan frontmatter — the implementer uses it to create the correct branch.

## Plan Frontmatter

```yaml
---
slug: [slug]
prd: .backlog/prds/PRD-[slug].md
status: draft | needs_review | approved | implemented | partially_implemented
planned_at: [timestamp]
planned_by: agent:planner
total_tasks: [count]
estimated_complexity: Low | Medium | High
branch: feat/[slug]
---
```

The `branch` field is **required**.

## Status Ownership

The planner sets status to `draft` or `needs_review`. Only a human sets `approved`.

## Write Boundaries

Only write to files within `.backlog/`:

- `.backlog/plans/*.md` (create plans)
- `.backlog/prds/*.md` (update PRD to link plan)

Do not write anywhere else. Read the entire codebase freely.
