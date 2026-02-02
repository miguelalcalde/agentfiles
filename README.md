# Agentfiles

> [!IMPORTANT]
> This is a work in progress. It is not ready for production use.
> This project has been de-prioritized in favor of agentworkflow which is more localized.

Portable agents, commands, and skills for Claude Code and Cursor. Fork this repo to build your own agent toolkit.

## Quick Start

**One-liner install:**

```bash
curl -fsSL https://raw.githubusercontent.com/miguelalcalde/ralphie/main/install.sh | bash
```

**Or clone manually:**

```bash
git clone git@github.com:YOUR_USERNAME/agentfiles.git ~/.agentfiles
cd ~/.agentfiles && ./setup.sh
```

## Platform Support

This toolkit works with both **Claude Code** and **Cursor**. Here's what each platform supports:

### Feature Compatibility

| Feature      | Claude Code | Cursor | Notes                                                                    |
| ------------ | ----------- | ------ | ------------------------------------------------------------------------ |
| **Skills**   | ✅          | ✅     | Same SKILL.md format, both platforms                                     |
| **Agents**   | ✅          | ✅     | Cursor calls them "subagents", reads `.claude/agents/` for compatibility |
| **Commands** | ✅          | ❌     | Claude Code only; Cursor uses different slash command system             |
| **Settings** | ✅          | ❌     | Claude uses `settings.json`; Cursor uses VSCode settings                 |

### Agent Field Compatibility

| Field           | Claude Code | Cursor | Notes                                                        |
| --------------- | ----------- | ------ | ------------------------------------------------------------ |
| `name`          | ✅          | ✅     | Agent identifier                                             |
| `description`   | ✅          | ✅     | When to invoke this agent                                    |
| `model`         | ✅          | ✅     | `inherit`, `fast`, or specific model ID                      |
| `color`         | ✅          | ❌     | UI customization (Claude only)                               |
| `tools`         | ✅          | ❌     | Tool restrictions (Claude only); Cursor inherits from parent |
| `readonly`      | ❓          | ✅     | Restrict write permissions (Cursor only)                     |
| `is_background` | ✅          | ✅     | Run without blocking                                         |

### What This Means

- **In Claude Code**: Full functionality—agents have tool restrictions, commands provide slash entry points
- **In Cursor**: Agents work as subagents, but `color` and `tools` fields are ignored. Commands don't create slash commands (invoke agents directly with `/agentname`)

## Architecture

```
commands/          → Interface layer (defines arguments, routes to agents)
agents/            → Implementation layer (full instructions, tool restrictions)
skills/            → Knowledge layer (workflows, templates, domain expertise)
```

**Commands** are thin wrappers that define the programmatic interface:

```yaml
---
description: Refine a PRD
arguments:
  - name: slug
    required: true
---
Invoke the **refiner** agent to refine PRD-$ARGUMENTS.slug.md
```

**Agents** contain the full implementation:

```yaml
---
name: refiner
description: Use to refine PRD documents
model: inherit
tools: Read, Write, Edit, Grep, Glob
---
You are the PRD Refiner agent...
```

This separation enables both interactive and programmatic use.

## Setup Commands

```bash
./setup.sh                      # Interactive install
./setup.sh --global cursor      # Global install, Cursor only
./setup.sh --local all          # Local install (current dir), both tools
./setup.sh --dry-run            # Preview changes without making them
./setup.sh status               # Show what's installed where
./setup.sh update               # Pull latest changes from git
./setup.sh validate             # Check repo structure is valid
./setup.sh unlink --global      # Remove global symlinks
```

## What Gets Installed

The setup script creates symlinks from your cloned repo to the tool config directories:

```
~/.claude/
├── agents/       → ~/.agentfiles/agents
├── commands/     → ~/.agentfiles/commands
├── skills/       → ~/.agentfiles/skills
└── settings.json → ~/.agentfiles/settings/claude.json

~/.cursor/
├── agents/       → ~/.agentfiles/agents
├── commands/     → ~/.agentfiles/commands  (not used by Cursor, but harmless)
└── skills/       → ~/.agentfiles/skills
```

## Workflow

Once installed, you have access to the feature workflow:

```
Backlog → /pick → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

| Command           | Agent       | Purpose                                    |
| ----------------- | ----------- | ------------------------------------------ |
| `/pick`           | picker      | Select task from backlog, create blank PRD |
| `/refine slug`    | refiner     | Complete and validate PRD                  |
| `/plan slug`      | planner     | Create implementation plan                 |
| `/implement slug` | implementer | Execute plan on feature branch             |

### Programmatic Chaining

Agents can be invoked programmatically for automation:

```bash
# Using Claude CLI
claude "/pick"
claude "/refine user-auth"
claude "/plan user-auth"
claude "/implement user-auth"

# Loop over multiple features
for slug in user-auth dashboard-analytics; do
  claude "/refine $slug"
  claude "/plan $slug"
done
```

In Cursor, invoke agents directly:

```
/picker select the next task
/refiner refine user-auth
/planner create plan for user-auth
```

## Naming Convention

The workflow uses descriptive **slugs** instead of numeric IDs:

| Artifact      | Format           | Example                           |
| ------------- | ---------------- | --------------------------------- |
| Backlog entry | `[slug] Title`   | `[user-auth] User Authentication` |
| PRD file      | `PRD-[slug].md`  | `PRD-user-auth.md`                |
| Plan file     | `PLAN-[slug].md` | `PLAN-user-auth.md`               |
| Branch        | `feat/[slug]`    | `feat/user-auth`                  |

Slugs are lowercase kebab-case, max 30 characters.

## Per-Project Setup

Each project using these agents needs a `docs/` folder:

```
your-project/
└── docs/
    ├── backlog.md
    ├── prds/
    │   └── PRD-user-auth.md
    └── plans/
        └── PLAN-user-auth.md
```

Example `backlog.md`:

```markdown
## Pending

### [user-auth] User Authentication

- **Priority**: P0 (Critical)
- **Status**: pending
- **Description**: Add user authentication with email/password
- **PRD**:
- **Plan**:
```

## Customizing

Since you've forked the repo, you can:

1. Add your own commands to `commands/`
2. Create new skills in `skills/`
3. Modify agents in `agents/`
4. Commit and push to your fork
5. On new machines, clone your fork and run setup

## Safety Features

- **Preview before action** — Use `--dry-run` to see what will happen
- **Explicit confirmation** — Asks before overwriting existing files
- **Timestamped backups** — Existing files are backed up as `filename.backup.YYYY-MM-DD`
- **Validation** — Run `./setup.sh validate` to check repo structure
- **Unlink command** — Easy removal with `./setup.sh unlink`

## Updating

```bash
./setup.sh update
```

Or manually:

```bash
cd ~/.agentfiles && git pull
```

Since symlinks point to your cloned repo, updates are immediate.
