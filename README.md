# Portable Agents

Agent-based feature workflow for Claude Code and Cursor.

## Setup

```bash
git clone git@github.com:miguelalcalde/ralphie.git ~/.agents
cd ~/.agents && chmod +x setup.sh && ./setup.sh
```

## What It Does

The setup script creates symlinks:

```
~/.agents/agents   →  ~/.claude/agents, ~/.cursor/agents
~/.agents/commands →  ~/.claude/commands, ~/.cursor/commands  
~/.agents/skills   →  ~/.claude/skills, ~/.cursor/skills
```

## Workflow

```
Backlog → /pick → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

| Command | Agent | Purpose |
|---------|-------|---------|
| `/pick` | picker | Select task from backlog, create blank PRD |
| `/refine FEAT-001` | refiner | Complete and validate PRD |
| `/plan FEAT-001` | planner | Create implementation plan |
| `/implement FEAT-001` | implementer | Execute plan on feature branch |

## Per-Project Setup

Each project needs a `docs/` folder:

```
your-project/
└── docs/
    ├── backlog.md
    ├── prds/
    └── plans/
```

## Updating

```bash
cd ~/.agents && git pull
```

Symlinks stay in place—updates are immediate.
