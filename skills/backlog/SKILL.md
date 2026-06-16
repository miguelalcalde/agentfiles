---
name: backlog
description: |
  Lightweight project backlog workflow. Use when starting a project, creating or
  maintaining a `.backlog/` folder, capturing inbox ideas, promoting work to
  GitHub Issues, checking for duplicate or overlapping tasks before add or
  promote, refining work into PRDs, planning implementation, or keeping project
  task memory current without a larger agent framework.
---

# Backlog

Use this skill to manage lightweight project memory in `.backlog/`.

The goal is useful continuity, not process ceremony. Create only the artifacts
that reduce ambiguity for the current task.

## Core Structure

When the user asks to initialize or use the backlog workflow, first check whether
`.backlog/` exists. If it does not exist and the user is starting a project or
explicitly asks to initialize the backlog, create:

```text
.backlog/
  inbox.md
  prds/
  plans/
  memory.md
```

Use these roles:

- `.backlog/inbox.md`: raw ideas, bugs, chores, and nitpicks not yet promoted
  to GitHub Issues.
- `.backlog/prds/PRD-[slug].md`: temporary drafting artifact for large or
  ambiguous work before it is promoted to GitHub. After promotion, delete it or
  replace it with a tiny pointer only if the user wants local traceability.
- `.backlog/plans/PLAN-[slug].md`: implementation sequencing for non-trivial
  changes.
- `.backlog/memory.md`: durable decisions, conventions, blockers, gotchas, and
  context future agents should remember.

GitHub Issues are canonical for any promoted task. If an item has a GitHub
Issue, GitHub owns its title, body, status, labels, discussion, and assignment.
Do not keep a second editable copy of the same promoted artifact in `.backlog/`.
Local PRDs are drafting buffers before promotion; local plans are execution
notes when implementation needs sequencing.

## Bootstrap Content

Create `.backlog/inbox.md` with:

```markdown
# Backlog Inbox

Raw ideas not yet promoted to GitHub Issues.

## Inbox
```

Create `.backlog/memory.md` with:

```markdown
# Backlog Memory

## Decisions

## Blockers

## Project Conventions

## Gotchas
```

Keep `prds/` and `plans/` empty until they are needed.

## Inbox Item Format

Use compact inbox items:

```markdown
- [ ] [type] [priority] **Title**. Short description.
```

Allowed types:

- `feat`: new user-facing capability
- `fix`: broken or incorrect behavior
- `nit`: small polish, copy, cleanup, tiny UX adjustment, or low-risk
  refinement

Allowed priorities:

- `high`
- `medium`
- `low`

Example:

```markdown
- [ ] [fix] [high] **Repair login redirect**. Users return to the wrong page after sign-in.
```

When an inbox item is promoted, remove it from `.backlog/inbox.md` or replace it
with a short link to the GitHub Issue. Do not track promoted status in the inbox.

## Slugs

Use a slug when a task gets a PRD, plan, branch, or issue link.

Rules:

- lowercase kebab-case
- max 30 characters
- only `a-z`, `0-9`, and `-`
- unique within `.backlog/prds/` and `.backlog/plans/`

Examples:

- `Repair login redirect` -> `login-redirect`
- `Dashboard analytics` -> `dashboard-analytics`

## Verify Before Add or Promote

Before adding an inbox item, creating a PRD or plan, or promoting work to
GitHub Issues, check whether the task already exists or overlaps with tracked
work. Do this every time unless the user explicitly asked to skip dedupe.

### Local checks

1. Read `.backlog/inbox.md` and scan titles, types, and short descriptions.
2. List `.backlog/prds/` and `.backlog/plans/` for matching slugs, titles, or
   scope.
3. Skim `.backlog/memory.md` for decisions, blockers, or gotchas that already
   cover the idea.

### Cloud checks

Prefer live GitHub search when `gh` is available:

```bash
gh issue list --state all --search "login redirect" --limit 20
gh issue list --state open --label "type:fix" --limit 50
gh issue view 123
gh pr list --state open --search "login redirect" --limit 10
```

Use keywords from the proposed title, affected area, error message, file path,
or user-facing symptom. Search open issues first, then closed issues when the
bug or feature may already have been filed or finished.

### Overlap signals

Treat these as likely duplicates or related work, not just exact title matches:

- Same symptom, bug, or user-facing behavior
- Same subsystem, route, component, or file path
- Same or near-identical slug
- One item is a subset or superset of another (`fix login redirect` vs
  `auth overhaul`)
- An open PR, plan, or PRD already tracks the same outcome

### When overlap is found

- **Exact duplicate**: do not add or promote. Link to the existing inbox item,
  issue, PRD, or plan.
- **Same work, different wording**: update or comment on the existing artifact.
  Do not create a second tracker.
- **Related but distinct**: create only if scope is genuinely separate. Cross-link
  in the body (`Related to #123`) or use GitHub blocked-by / blocks references
  when one depends on the other.
- **Superseded**: close, remove, or archive the stale item and point to the
  canonical one.
- **Uncertain**: tell the user what matched and ask whether to extend the
  existing item or create a new one.

After resolving overlap, proceed with Capture, Promote, Refine, or Plan.

## Workflow

### Capture

When the user shares an idea, bug, nitpick, or task:

1. Ensure `.backlog/` exists if the user wants the backlog workflow active.
2. Run **Verify Before Add or Promote** against local and cloud trackers.
3. If the item is rough or not ready for GitHub, add it under `## Inbox` in
   `.backlog/inbox.md`.
4. If the item is ready to track, create or update a GitHub Issue when the user
   wants GitHub-backed tracking.
5. Choose type and priority from the user's wording and project context.
6. Keep the item short. Put deeper context in a PRD only when needed.

### Promote

When promoting local work to GitHub Issues:

1. Run **Verify Before Add or Promote** again, focusing on GitHub Issues and
   any open PRs for the same area.
2. If the work has a PRD, create or update the GitHub Issue from the PRD
   content.
3. Verify the GitHub Issue contains the canonical title, body, labels, and
   acceptance criteria.
4. Remove the inbox item or replace it with the issue URL.
5. Delete the promoted PRD unless the user explicitly wants a tiny pointer file.
6. If keeping a pointer file, include only frontmatter and a short note that the
   GitHub Issue is canonical.
7. Choose labels from the user's wording and project context.

Pointer file example:

```markdown
---
slug: [slug]
status: promoted
issue: [GitHub issue URL]
promoted_at: [ISO-8601 timestamp]
---

Canonical artifact lives in GitHub Issue #[number].
```

Use this GitHub label framework:

- `type:feat`, `type:fix`, `type:nit`
- `priority:high`, `priority:medium`, `priority:low`
- `status:unknown`, `status:ready`, `status:blocked`

Use exactly one `type:*` label:

- `type:feat`: new behavior, capability, surface area, or supported workflow.
- `type:fix`: broken, incorrect, confusing, or regressed behavior.
- `type:nit`: small polish, copy, cleanup, tiny UX adjustment, or low-risk
  refinement.

Use at most one `priority:*` label:

- `priority:high`: important soon, blocks other work, or meaningfully affects
  core UX.
- `priority:medium`: valuable, but not urgent or blocking.
- `priority:low`: nice-to-have, opportunistic, or exploratory.

Use exactly one `status:*` label for promoted open issues:

- `status:unknown`: default promoted state. Needs clarification, research,
  scoping, or acceptance criteria.
- `status:ready`: clear enough to implement without unresolved product
  decisions.
- `status:blocked`: cannot proceed until a decision or dependency is resolved.
  Link the blocking issue or decision in the issue body or a comment.

### Triage

When choosing what to work on:

1. Prefer `high`, then `medium`, then `low`.
2. Prefer unblocked, well-scoped tasks.
3. For promoted work, read the GitHub Issue first and treat it as canonical.
4. For unpromoted inbox work, either promote it to a GitHub Issue or keep it
   local only if the user wants a tiny one-off task.
5. Add or derive a slug if the task needs a PRD, plan, branch, or issue link.

### Refine

Create a PRD only when the task benefits from product-level clarification.
First run **Verify Before Add or Promote** so the PRD does not duplicate an
existing issue, inbox item, or plan.

- user-facing feature
- ambiguous behavior
- multiple acceptance criteria
- meaningful scope or tradeoffs
- work likely to be resumed later

Skip the PRD for obvious fixes, small chores, and nitpicks.

PRD path:

```text
.backlog/prds/PRD-[slug].md
```

PRD template:

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

## Out of Scope

## Open Questions
```

Use statuses:

- `draft`: useful but still being shaped
- `ready`: clear enough to plan or implement
- `blocked`: needs a human decision or external dependency
- `done`: implemented or no longer needed

### Plan

Create a plan only when implementation needs sequencing. First run **Verify
Before Add or Promote** so the plan does not duplicate existing tracked work.

- multiple files or subsystems
- migration, data, auth, payments, security, or deployment risk
- uncertain tests or verification steps
- work that an agent should execute later

Plan path:

```text
.backlog/plans/PLAN-[slug].md
```

Plan template:

```markdown
---
slug: [slug]
status: draft
issue: [GitHub issue URL or blank]
prd: [PRD path or blank]
created_at: [ISO-8601 timestamp]
---

# Plan: [Title]

## Summary

## Tasks

- [ ] [Task with file paths and verification]

## Verification

## Risks

## Notes
```

Use statuses:

- `draft`: being planned
- `ready`: clear enough to execute
- `in_progress`: currently being implemented
- `blocked`: cannot continue without input
- `done`: implemented and verified

### Execute

When implementing from the backlog:

1. Read the relevant GitHub Issue or inbox item, plus any PRD and plan.
2. Keep edits scoped to the task.
3. Update the plan checklist if a plan exists.
4. Update GitHub Issue status through normal GitHub workflow when the work is
   promoted.
5. Add durable decisions, blockers, or gotchas to `.backlog/memory.md`.

Do not create PRDs or plans retroactively unless they would help future work.

## GitHub Issues

Use GitHub Issues as the source of truth for promoted work:

- GitHub Issue: canonical title, body, status, labels, discussion, assignment,
  and automation.
- `.backlog/inbox.md`: local ideas not yet promoted.
- PRD: temporary local drafting buffer before promotion; not a parallel copy
  after promotion.
- Plan: local implementation sequence when needed; may reference a GitHub Issue.
- Pull request: code review and final execution record.

When linking them, include issue URLs in the PRD or plan frontmatter. Prefer
GitHub closing keywords such as `Closes #123` in pull requests.

Avoid two-way sync unless the user explicitly asks for it. It needs stable IDs,
conflict handling, deletion behavior, label mapping, and rules for edits from
multiple actors.

## Migration

If an existing project has `.backlog/backlog.md`, treat it as a legacy local
backlog:

1. Ask before rewriting it unless the user explicitly requested migration.
2. Move rough, unpromoted items to `.backlog/inbox.md`.
3. Move or recreate promoted work as GitHub Issues.
4. Stop using `.backlog/backlog.md` once GitHub Issues are canonical.

## Rules

- Prefer the smallest useful artifact.
- Verify local and cloud trackers for duplicates and overlap before adding or
  promoting work.
- Do not require PRDs for small fixes.
- Do not require plans for obvious one-step changes.
- Keep inbox entries readable in plain Markdown.
- Never let Markdown status override GitHub Issue status.
- Do not maintain duplicate editable copies of promoted issue content locally
  and in GitHub.
- Preserve human-written memory and decisions.
- Before editing `.backlog/`, read the relevant existing files.
- When a task is blocked, write the blocker where future agents will see it.
