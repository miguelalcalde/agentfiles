# Agentfiles

This repository publishes installable skills.

Install the backlog skill with:

```bash
npx skills add mikemajara/skills --skill backlog
```

Install the Todoist API skill with:

```bash
npx skills add mikemajara/skills --skill todoist-api
```

## backlog

The skill gives an LLM a simple project workflow for bootstrapping and using a
local `.backlog/` folder while treating GitHub Issues as canonical for promoted
work:

```text
.backlog/
  inbox.md
  issues.md
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
- `issues.md` is a generated/read-only mirror of GitHub Issues.
- `memory.md` keeps durable decisions, conventions, blockers, and gotchas.
- PRDs are created only when the task needs product-level clarification.
- Plans are created only when implementation needs sequencing or risk tracking.
- Small fixes and nitpicks can stay in the inbox until they are worth promoting.

See `CHANGELOG.md` for migration notes when updating projects that already have
an older `.backlog/` layout.

The skill includes an optional `scripts/backlog-sync.mjs` helper that downstream
projects can run from the installed skill or copy into their own `scripts/`
directory. It regenerates `.backlog/issues.md` from GitHub Issues with the
GitHub CLI, discovering the repo from `git config --get remote.origin.url` by
default.

## todoist-api

The `todoist-api` skill is a Todoist API v1 reference for agents that need to
build or operate direct Todoist HTTP integrations. It covers authentication,
endpoint paths, request fields, pagination, error handling, and migration
caveats without encoding personal task-management workflow rules.
