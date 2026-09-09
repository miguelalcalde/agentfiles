---
name: issue-kickoff
description: |
  Use when kicking off implementation on a GitHub issue that is already ready (plan/AC locked via backlog or equivalent): how to mention the implementer in Cursor, shape the kickoff comment, and what the PR handoff expects. Not for shaping the plan — that is backlog (or the repo's own refine path).
---

# Issue kickoff

Thin rules for **starting** implement work on an issue that is already ready.
Readiness (AC checkable, open questions empty, decisions locked) is owned by
**backlog** (or the project's equivalent). If the issue is not ready, do not
kick off; send it back to refine.

Kickoffs go through **Cursor** on the GitHub issue. The implementer mention is
`@cursor`.

## When to use

- An issue is in implement phase (or clearly ready to implement).
- A PM / owner needs to post the kickoff comment that triggers Cursor.
- A follow-up fix on the same issue needs a **new** kickoff comment (same rules).

## Kickoff comment

1. Post an **issue comment** on the GitHub issue (not only chat).
2. Put `@cursor` as the **first token** of the comment body (start of the first
   line). A mention later in the comment does **not** count.
3. After `@cursor`, give a short brief. Prefer pointing at the issue body as the
   plan — do not paste a second conflicting spec.
4. Extra instructions later = **new comments** (traceability). Fresh trigger =
   new comment that again starts with `@cursor`.

### Required content (after `@cursor`)

| Field | What to say |
| ----- | ----------- |
| Action | implement / fix this issue (or name the PR/branch to update) |
| Base | branch to branch from and open the PR against (e.g. `dev`) |
| Link | `Closes #N` (or equivalent) when the PR should close the issue |
| Scope | "Follow the plan and AC on the issue" + any hard out-of-scope neighbors |
| Merge | Do **not** merge; leave Manual QA for the human owner |

### Example

```text
@cursor implement #97

Branch from `dev`, PR against `dev`, `Closes #97`.

Follow the Locked decisions and AC on the issue body.
Do not implement neighboring issues.

When the PR is ready: leave Manual QA in comments; do not merge.
```

### Follow-up after QA fail

Update the **issue** with the new lock (so the plan stays canonical), then post
a **new** kickoff that again starts with `@cursor`, pointing at the same
PR/branch if one exists.

```text
@cursor fix #97 on PR #105 / branch `cursor/…`

QA fail: <one-line fact>.
Locked now: <single option — no ambiguity>.
Update the same draft PR. Leave Manual QA. Do not merge.
```

## PR handoff (expectations for Cursor)

- PR against the base named in the kickoff.
- Title/body and `[Unreleased]` changelog bullets follow the **product locale**
  of the repo when the change is user-facing (e.g. Super App → Spanish).
- Do not merge from the kickoff path unless the human owner said so.

## Out of scope

- Shaping plans, AC, or "is this ready?" — **backlog**.
- Label schema, phases, inbox/promote — **backlog**.
- Harness-specific bans (e.g. Cloud Agents from Grok Bot) — persona or Grok-only
  routing, not this skill.
- Implementing the code from Grok Bot — kickoff is an issue comment Cursor can see.
