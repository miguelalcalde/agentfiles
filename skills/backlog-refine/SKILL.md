---
name: backlog-refine
description: |
  Refine backlog work into clear product scope, acceptance criteria, and
  agent-safe edge-case behavior. Use when an issue needs clarification,
  status:unknown work should become status:ready, the user asks to refine or
  write a PRD, harden a spec against failure modes, or a multi-agent handoff
  targets the refine phase. Pair with the backlog contract skill for labels,
  dedupe, and scripts. Prefer updating the GitHub Issue; use a local PRD only
  as a temporary drafting buffer.
---

# Backlog Refine

Refine turns ambiguous work into implementable product clarity: problem, goal,
requirements, acceptance criteria, and out-of-scope edges. It also hardens the
spec so an implementing agent is not forced to invent stop/continue, state, or
failure behavior.

Shared law (layout, labels, verify/dedupe, GitHub canonical rules) lives in
the `backlog` skill. Read it when those rules are needed. Prefer
`backlog/references/phase-skills.md` for handoff shape.

## When to run

Create deeper refinement (and a PRD only when useful) for:

- user-facing features
- ambiguous behavior
- multiple acceptance criteria
- meaningful scope or tradeoffs
- work likely to be resumed later

Skip PRDs for obvious fixes, small chores, and nitpicks. Those can move
straight to `status:ready` with a tightened issue body, or stay as inbox
items if unpromoted. For those trivial items, skip the full Spec hardening
pass and note `hardening skipped: trivial`.

If facts are still missing, hand off to `backlog-research` first.

## Input contract

Expect a handoff packet:

1. Issue number (preferred) or inbox title/slug
2. Current `status:*` label
3. Paths to any existing PRD/plan
4. Optional helpers:

```bash
node path/to/skills/backlog/scripts/backlog-issue-audit.mjs 123 --format json
node path/to/skills/backlog/scripts/backlog-refinement-candidates.mjs --format json
```

## Procedure

1. **Claim work**: set `status:doing` on the promoted issue before editing.
2. **Verify** with the `backlog` skill's Verify Before Add or Promote rules so
   refinement does not duplicate existing issues, inbox items, or plans.
3. **Decide artifact size**:
   - Small/clear: update the GitHub Issue body in place (canonical).
   - Large/ambiguous: draft locally, then promote content into the issue.
4. **Local PRD only when needed** at:

```text
.backlog/prds/PRD-[slug].md
```

Template:

```markdown
---
slug: [slug]
title: [title]
status: draft
issue: [GitHub issue URL or blank]
created_at: [ISO-8601 timestamp]
---

# [Title]

## Problem

## Goal

## Requirements

## Acceptance Criteria

- [ ]

## Edge Cases

| Scenario | Expected behavior | Disposition |
| --- | --- | --- |
| | | AC / open question / out of scope |

## Out of Scope

## Open Questions
```

PRD statuses: `draft`, `ready`, `blocked`, `done`.

5. **Spec hardening** (required before `status:ready`, unless trivial skip):
   Walk these categories **in order**. Skip a category only with an explicit
   `N/A — <reason>` note (not a silent omit):

   1. User types
   2. Contexts of use
   3. Unexpected inputs / system failures
   4. User error
   5. Feature interactions
   6. Load
   7. Security and privacy
   8. Accessibility

   For each real hit, add a row:

   `Scenario → Expected behavior → AC | open question | out of scope`

   Hard rules:

   - No shrug language ("log and continue", "handle errors", emoji stand-ins).
     When money, state, or side effects are involved, name **stop vs continue**,
     what is written, and what the user/admin sees.
   - Happy-path-only acceptance criteria are not enough when the pass finds
     gaps.
   - Fold defined behaviors into Acceptance Criteria (or the issue body).
     Keep the Edge Cases table as the working pass, then collapse it.
   - Unresolved product decisions stay in Open Questions. If a human must
     decide before implement, prefer `status:blocked` over inventing behavior.

6. **Promote draft content into GitHub** when the issue exists: title, body,
   labels, and acceptance criteria on the issue are canonical. Include the
   hardened behaviors (AC and any remaining open questions). Delete the local
   PRD after promotion, or keep only a tiny pointer if the user wants local
   traceability.
7. **Label outcome**:
   - Clear enough to implement **and** hardening done (or trivial skip) →
     `status:ready` (remove `status:doing` / `status:unknown`)
   - Needs a human decision → `status:blocked` with the question linked
8. Clear the `status:doing` claim when this refine agent stops.

## Output contract

- GitHub Issue (promoted work) has clear scope and acceptance criteria, or
  explicit open questions under `status:blocked`
- Non-trivial work includes evidence of the Spec hardening pass (table and/or
  AC coverage, plus N/A reasons where categories were skipped)
- Optional local PRD only as a draft buffer, never a second editable source
  of truth after promotion
- No implementation plan unless the user also asked for `backlog-plan`

## Done when

Stop when:

- `status:ready`: implementable without unresolved product decisions, and an
  implementing agent would not need to invent stop/continue, ledger/state,
  idempotency, or failure-recovery behavior for in-scope paths, **or**
- `status:blocked`: concrete blocker / open questions linked

Hand off to `backlog-plan` only when sequencing/risk warrants it.
