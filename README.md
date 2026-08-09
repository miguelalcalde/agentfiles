# Agentfiles

This repository publishes installable skills.

Install the backlog contract skill with:

```bash
npx skills add mikemajara/skills --skill backlog
```

Optional phase skills for multi-agent workflows (install alongside `backlog`):

```bash
npx skills add mikemajara/skills --skill backlog-research
npx skills add mikemajara/skills --skill backlog-refine
npx skills add mikemajara/skills --skill backlog-plan
```

Install the Todoist API skill with:

```bash
npx skills add mikemajara/skills --skill todoist-api
```

Install the commit-message skill with:

```bash
npx skills add mikemajara/skills --skill commit
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

`backlog` is the **contract** skill: layout, labels, verify/dedupe, Review,
Triage, Capture, Promote, and shared scripts. For dedicated phase passes,
prefer the thin skills:

| Skill | Phase |
| --- | --- |
| `backlog-research` | Gather facts for thin/ambiguous issues |
| `backlog-refine` | Product clarity and acceptance criteria |
| `backlog-plan` | Implementation sequencing |

See `skills/backlog/references/phase-skills.md` for the phase map and manual
multi-agent handoff packet. Hook automation is deferred.

Example prompts:

```text
Use the backlog skill to initialize this project.
Use the backlog skill to capture this task.
Use backlog-research on issue #123.
Use backlog-refine on the next status:unknown issue.
Use backlog-plan for the auth cleanup task.
```

The skill intentionally keeps the workflow lightweight:

- `inbox.md` captures rough ideas that are not yet GitHub Issues.
- `memory.md` keeps durable decisions, conventions, blockers, and gotchas.
- PRDs are created only when the task needs product-level clarification.
- Plans are created only when implementation needs sequencing or risk tracking.
- Small fixes and nitpicks can stay in the inbox until they are worth promoting.

See `CHANGELOG.md` for migration notes when updating projects that already have
an older `.backlog/` layout.

To bootstrap a project idempotently after installing the skill, run:

```bash
node path/to/skills/backlog/scripts/backlog-setup.mjs
```

That creates missing `.backlog/` starter files and upserts the canonical GitHub
labels. Use `--check` to verify an existing repo without making changes.

To regenerate a read-only GitHub Issues snapshot for local visibility:

```bash
node path/to/skills/backlog/scripts/backlog-sync.mjs
```

GitHub remains canonical; `.backlog/issues.md` is generated output only.

## todoist-api

The `todoist-api` skill is a Todoist API v1 reference for agents that need to
build or operate direct Todoist HTTP integrations. It covers authentication,
endpoint paths, request fields, pagination, error handling, and migration
caveats without encoding personal task-management workflow rules.

## sdlc-first-principles

The `sdlc-first-principles` skill applies Elon Musk's five-step process
improvement algorithm to software delivery: challenge requirements, delete
unnecessary work, simplify what remains, accelerate cycle time, and automate
last.

Use it to review requirements, tickets, planning rituals, code review, CI/CD,
release processes, tests, incident response, developer tooling, automation, or
team operating procedures.
