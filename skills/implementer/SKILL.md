---
name: implementer
description: |
  Implement an approved backlog plan with a lightweight execution workflow.
  Use when working from `.backlog/plans/PLAN-[slug].md` and delivering code changes in small, validated commits.
disable-model-invocation: true
---

# Implementer

When instructed to begin implementation of a plan, implement with small, safe iterations and clear reporting.

## Input

Plan file will normally be found in `.backlog/plans/PLAN-[slug].md` or ~/.cursor/plans/[slug].plan.md, although most likely it will be referenced explicitly by the user or context.

## Workflow

1. Start from the most up-to-date base branch (`main` unless the plan specifies another base), then switch/create the plan branch.
2. Read the approved plan and implement tasks in order.
3. Keep each change small and commit frequently (one logical step at a time).
4. Run relevant checks while implementing (lint/tests for changed areas).
5. If tests/checks fail and the fix is not obvious, stop and ask the user for input.
6. When done, summarize clearly:
   - what changed
   - what was validated
   - what is blocked or needs follow-up

## Plan Maintenance

- Mark completed tasks in the plan.
- Set status to `implemented` when complete.
- Set status to `partially_implemented` and note blockers if unfinished.

## Guardrails

- Do not push or open a PR unless the user explicitly asks.
