# Agentfiles

This repository publishes installable skills.

Install the backlog skill with:

```bash
npx skills add mikemajara/skills --skill backlog
```

Install the SDLC first-principles skill with:

```bash
npx skills add mikemajara/skills --skill sdlc-first-principles
```

## backlog

The skill gives an LLM a simple project workflow for bootstrapping and using a
local `.backlog/` folder while treating GitHub Issues as canonical for promoted
work:

```text
.backlog/
  inbox.md
  prds/
  plans/
  memory.md
```

Use it when starting a project or when you want task work to be captured without
turning the repository into a larger agent framework.

Example prompts:

```text
Use the backlog skill to initialize this project.
Use the backlog skill to capture this task.
Use the backlog skill to refine the next ready backlog item.
Use the backlog skill to plan the auth cleanup task.
```

The skill intentionally keeps the workflow lightweight:

- `inbox.md` captures rough ideas that are not yet GitHub Issues.
- `memory.md` keeps durable decisions, conventions, blockers, and gotchas.
- GitHub Issues are shaped implementable units (goal, scope, AC)—one issue ≈ one
  coherent first PR.
- PRDs are product umbrellas for multi-issue drafting; promote by creating
  linked issues, not by pasting the PRD into an issue body.
- Plans are per-issue sequencing (how/order), not tickets or second product docs.
- Small fixes and nitpicks can stay in the inbox until they are worth promoting.

See `CHANGELOG.md` for migration notes when updating projects that already have
an older `.backlog/` layout.

To bootstrap a project idempotently after installing the skill, run:

```bash
node path/to/skills/backlog/scripts/backlog-setup.mjs
```

That creates missing `.backlog/` starter files, injects an agent hint into
`AGENTS.md` / `CLAUDE.md` so agents always check `.backlog/memory.md` and the
inbox, and upserts the canonical GitHub labels. Use `--check` to verify an
existing repo without making changes. Use `--skip-agent-hint` to leave agent
instruction files untouched.

To regenerate a read-only GitHub Issues snapshot for local visibility:

```bash
node path/to/skills/backlog/scripts/backlog-sync.mjs
```

GitHub remains canonical; `.backlog/issues.md` is generated output only.

## sdlc-first-principles

The `sdlc-first-principles` skill applies Elon Musk's five-step process
improvement algorithm to software delivery: challenge requirements, delete
unnecessary work, simplify what remains, accelerate cycle time, and automate
last.

Use it to review requirements, tickets, planning rituals, code review, CI/CD,
release processes, tests, incident response, developer tooling, automation, or
team operating procedures.
