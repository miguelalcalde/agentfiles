---
name: triage
description: |
  Select a task from the backlog and create an initial PRD.
  Use when picking the next task to work on and bootstrapping its PRD from the template.
disable-model-invocation: true
---

# Triage Methodology

Select a task from the backlog and create an initial PRD document.

## Inputs

- **Backlog**: `.backlog/backlog.md`
- **PRD template**: `skills/backlog/templates/prd-template.md`

## Process

1. **Read the backlog** at `.backlog/backlog.md`
2. **Select a task** from the `## Pending` section — default: highest priority first (`HIGH` > `MED` > `LOW`), then top-to-bottom order
3. **Derive the slug** from the feature name (see Slug Rules below)
4. **Copy the PRD template** and fill in the frontmatter (`slug`, `title`, `created_at`) and seed the Problem Statement with the task description from the backlog
5. **Save the PRD** to `.backlog/prds/PRD-[slug].md`
6. **Update the backlog**: move the task from `## Pending` to `## In Progress` and prepend the slug — e.g., `- [ ] [user-auth] [FEAT] [HIGH] **User Authentication**. …`

## Slug Rules

The slug is the canonical identifier used throughout the workflow.

- **Format**: lowercase kebab-case
- **Max length**: 30 characters
- **Allowed characters**: `a-z`, `0-9`, `-`
- **Derivation**: extract key words from the feature name
- **Must be unique**: check existing PRDs in `.backlog/prds/` before finalising
- **Examples**:
  - "User Authentication" → `user-auth`
  - "Dashboard Analytics" → `dashboard-analytics`
  - "API Rate Limiting" → `api-rate-limiting`

## PRD Frontmatter

When creating the PRD, fill in these frontmatter fields from the template:

```yaml
---
slug: [derived-slug]
title: [Feature Title from backlog]
status: blank
created_at: [ISO 8601 timestamp]
created_by: agent:triager
---
```

Leave all other frontmatter fields at their template defaults.

## Output

After completing, report:

- Which task was selected and why
- The derived slug
- Path to the created PRD
- Any concerns or ambiguities noted

## Rules

- Only pick tasks from the `## Pending` section
- Never touch tasks under `## In Progress` or `## Done`
- If no pending tasks exist, report this and stop
- If the task description is ambiguous, still create the PRD but note the ambiguity in `Open Questions`

## Write Boundaries

Only write to files within `.backlog/`:

- `.backlog/backlog.md` (move task to In Progress, add slug)
- `.backlog/prds/*.md` (create new PRD)

Do not write anywhere else.
