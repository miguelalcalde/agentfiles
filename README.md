# Agentfiles

Portable agents, commands, skills, and file templates for Claude Code and Cursor.

## Quick Start

Install from a single command (no manual clone required):

```bash
curl -fsSL https://raw.githubusercontent.com/miguelalcalde/agentfiles/main/setup.sh | bash
```

Pass flags when piping to bash:

```bash
curl -fsSL https://raw.githubusercontent.com/miguelalcalde/agentfiles/main/setup.sh | bash -s -- --global --verbose
```

For local development of this repo:

```bash
git clone git@github.com:miguelalcalde/agentfiles.git
cd agentfiles
./setup.sh --help
```

## Getting Started

1. Run the installer interactively (`curl ... | bash`).
2. Choose what to install (`agents`, `skills`, `commands`, `files`).
3. Choose scope (`--global`, `--local`, or custom path).
4. Choose `symlink` or `copy` mode.
5. Choose whether existing paths should be overwritten.

Useful flags:

- `--dry-run`: preview actions without writing.
- `--verbose`: show detailed diagnostics and decision logs.
- `--agents x,y`, `--skills x,y`, `--commands x,y`, `--files x,y`: install selected items.

## Core Concepts

### Agents

Agents are the implementation layer: behavior, process, and tool constraints.

Example: `agents/triager.md`

- Reads `.backlog/backlog.md`
- Selects the next pending task
- Creates a PRD in `.backlog/prds/`

### Commands

Commands are thin entrypoints that route to agents.

Example: `commands/triage.md`

- `/triage` delegates to the `triager` agent.
- This was previously mapped to `picker`; it is now `triager`.

### Skills

Skills are reusable knowledge packs and templates used by agents.

Examples:

- `skills/backlog/`
- `skills/commit/`

### Files (file groups)

`files` are top-level template directories that get installed into hidden project folders.

Example:

- Source file group: `backlog/`
- Installed target: `.backlog/`

So running setup with `--files backlog` materializes project scaffolding like `.backlog/config.yaml`, `.backlog/prds/`, `.backlog/plans/`.

## Platform Support

| Feature | Claude Code | Cursor | Notes |
| --- | --- | --- | --- |
| Skills | ✅ | ✅ | Same SKILL.md format |
| Agents | ✅ | ✅ | Cursor uses subagents |
| Commands | ✅ | ❌ | Claude slash commands only |
| Settings | ✅ | ❌ | Claude settings are separate |

## Install Layout

Canonical install root:

```
~/.agents/
├── manifest.json
├── agents/
├── commands/
├── skills/
└── backups/
```

Tool-specific links/copies:

```
~/.claude/
├── agents/*.md
├── commands/*.md
└── skills/*

~/.cursor/
├── agents/*.md
├── commands/*.md
└── skills/*
```

## Overwrite and Backups

- Interactive installs ask once: `Overwrite existing paths when present? [y/N]`.
- If overwrite is enabled, replaced targets are backed up under:

```
~/.agents/backups/<run-id>/...
```

- Backup paths mirror the original target structure (for easier restore).
- Backups are intentionally outside install folders to avoid autodiscovery pollution.

## Bootstrap Behavior

When run via `curl | bash`, the installer bootstraps from a temporary clone and cleans it up automatically after execution. It does not keep a persistent bootstrap repo in home directories.

## Setup Examples

```bash
# Fully interactive
./setup.sh

# Install selected components
./setup.sh --agents triager,planner --skills backlog --commands triage,plan --global --tools all

# Install project templates locally
./setup.sh --files backlog --local --mode copy

# Debug decisions and path detection
./setup.sh --skills backlog --global --tools claude --verbose
```

## Workflow Example

Feature workflow command chain:

```
/triage -> /refine <slug> -> /plan <slug> -> /implement <slug>
```

| Command | Agent | Purpose |
| --- | --- | --- |
| `/triage` | `triager` | Select next backlog task and create initial PRD |
| `/refine <slug>` | `refiner` | Complete/validate PRD |
| `/plan <slug>` | `planner` | Produce implementation plan |
| `/implement <slug>` | `implementer` | Execute plan changes |

In Cursor, invoke the agent directly (for example `/triager`).

## Development Notes

- This repository is the development source.
- End users should prefer installation through `curl -fsSL ... | bash`.
- To contribute, modify files in this repo and push updates to `main`.
