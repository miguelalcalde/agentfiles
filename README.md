# Agentfiles

This repository publishes installable skills.

```bash
npx skills add mikemajara/skills --skill backlog
npx skills add mikemajara/skills --skill sdlc-first-principles
```

## backlog

Workflow for capturing work and moving issues through research → refine →
implement → qa. GitHub Issues are the default source of truth.

```text
.backlog/
  inbox.md
  plans/
  memory.md
```

- `inbox.md` — optional local scratch until promoted.
- `plans/` — product specs only (what/why/in/out/AC), when the issue body is not enough.
- `memory.md` — durable decisions, blockers, conventions, gotchas.
- A **plan** is the product spec for one issue. Split oversized work into more issues. No implementation-sequence docs.

Example prompts:

```text
Use the backlog skill to initialize this project.
Use the backlog skill to capture this task.
Use the backlog skill to refine the next issue.
```

After install:

```bash
node path/to/skills/backlog/scripts/backlog-setup.mjs
```

`--check` reports skill version and label schema. See `CHANGELOG.md` for
label-schema 3 migration (`status:unknown` / `status:ready` → `phase:*` +
`status:open`).

## sdlc-first-principles

The `sdlc-first-principles` skill applies Elon Musk's five-step process
improvement algorithm to software delivery: challenge requirements, delete
unnecessary work, simplify what remains, accelerate cycle time, and automate
last.
