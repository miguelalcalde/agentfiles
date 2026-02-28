---
name: implement
description: |
  Implement an approved plan in small, verifiable steps.
  Use when executing `.backlog/plans/PLAN-[slug].md` tasks on a feature branch with frequent commits and no pushes.
disable-model-invocation: true
---

# Implementation Methodology

Execute an approved plan safely and incrementally.

## Inputs

- **Plan path**: `.backlog/plans/PLAN-[slug].md`

## Process

1. **Read the plan** and verify status is `approved`
2. **Use the plan branch** from frontmatter (`branch: feat/[slug]`)
3. **Implement tasks in order**:
   - Make the smallest useful change
   - Run relevant lint/tests
   - Commit immediately with a clear message
   - Mark the task complete in the plan
4. **Finish**:
   - Run final verification (lint/tests relevant to changed areas)
   - Update plan status to `implemented` (or `partially_implemented` if blocked)
   - Record blockers directly in the plan

## Commit Guidance

- Commit after each logical task or subtask
- Prefer small commits over large batches
- Keep commit messages specific to the completed task

## Rules

- NEVER implement from a non-approved plan
- NEVER work on `main`; use the plan's feature branch
- NEVER push (`git push`) automatically
- NEVER create PRs automatically
- NEVER force push
- NEVER sign commits (`-S`, `--gpg-sign`)

## Write Boundaries

- Source code files required by the approved plan
- `.backlog/plans/*.md` for task/status updates
