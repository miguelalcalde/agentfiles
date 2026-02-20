---
name: refine
description: |
  Refine a PRD to ensure it is complete, well-structured, and ready for planning.
  Use when iterating on an existing PRD or completing a blank one.
disable-model-invocation: true
---

# Refinement Methodology

Ensure a PRD is complete, well-structured, and ready for planning.

## Inputs

- **PRD path**: `.backlog/prds/PRD-[slug].md` (or a custom location provided by the user)
- **PRD template**: `skills/backlog/templates/prd-template.md`

## Process

1. **Read the PRD** specified by the user
2. **Review against the template** — identify missing or weak sections
3. **Research the codebase** to understand:
   - Current architecture and patterns
   - Related existing functionality
   - Technical constraints
4. **Fill in missing sections** with detailed, actionable content
5. **Update PRD frontmatter** with refinement status
6. **Save the updated PRD**

## Quality Checklist

- [ ] Problem statement is clear and specific
- [ ] Proposed solution is technically feasible
- [ ] Acceptance criteria are testable
- [ ] Dependencies are identified
- [ ] Out of scope is defined
- [ ] Open questions are documented (if any)

## PRD Frontmatter

```yaml
---
slug: [slug]
title: Feature Title
status: refined | needs_review
refined_at: [timestamp]
refined_by: agent:refiner
iterations: [count]
quality_score: [0-100]
open_questions: [count]
---
```

## Status Ownership

The refiner sets status to `refined` or `needs_review`. Only a human sets `approved`. Never approve your own work.

## Rules

- If critical information is missing and cannot be inferred, add to `open_questions`
- Preserve any human edits or comments in the PRD
- Each refinement increments the `iterations` counter
- Be specific and actionable — avoid vague requirements

## Write Boundaries

Only write to files within `.backlog/`:

- `.backlog/prds/*.md` (update PRDs)

Do not write anywhere else. Read the entire codebase freely.
