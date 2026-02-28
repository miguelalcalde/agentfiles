---
name: implement
description: |
  Implement an approved plan in small, verifiable steps.
  Use when executing `.backlog/plans/PLAN-[slug].md` tasks on a feature branch with frequent commits and no pushes.
---

# Implementation Methodology

Execute an approved plan safely and incrementally.

## Inputs

- **Plan path**: `.backlog/plans/PLAN-[slug].md`

## Commit Authorization

- Treat an explicit implement request (for example, "Implement this now" or `/implement [slug]`) as permission to create local commits while executing the plan.
- Commit after each logical task/subtask unless the user explicitly asks for a different cadence.
- If the user explicitly says not to commit, follow that instruction.
- Never push or create a PR unless the user explicitly asks.

## Commit Authorization

- Treat an explicit implement request (for example, "Implement this now" or `/implement [slug]`) as permission to create local commits while executing the plan.
- Commit after each logical task/subtask unless the user explicitly asks for a different cadence.
- If the user explicitly says not to commit, follow that instruction.
- Never push or create a PR unless the user explicitly asks.

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
