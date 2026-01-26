# Agentfiles

Portable agents for Claude Code and Cursor. Fork this repo to build your own agent toolkit.

## Quick Start

```bash
# Fork this repo on GitHub, then:
git clone git@github.com:YOUR_USERNAME/agentfiles.git ~/.agentfiles
cd ~/.agentfiles && ./setup.sh
```

## Commands

```bash
./setup.sh                      # Interactive install
./setup.sh --global cursor      # Global install, Cursor only
./setup.sh --local all          # Local install (current dir), both tools
./setup.sh --dry-run            # Preview changes without making them
./setup.sh status               # Show what's installed where
./setup.sh unlink --global      # Remove global symlinks
```

## What Gets Installed

The setup script creates symlinks from your cloned repo to the tool config directories:

```
~/.claude/
├── agents/     -> ~/.agentfiles/agents
├── commands/   -> ~/.agentfiles/commands
├── skills/     -> ~/.agentfiles/skills
└── settings.json -> ~/.agentfiles/settings/claude.json

~/.cursor/
├── agents/     -> ~/.agentfiles/agents
├── commands/   -> ~/.agentfiles/commands
└── skills/     -> ~/.agentfiles/skills
```

## Customizing

Since you've forked the repo, you can:

1. Add your own commands to `commands/`
2. Create new skills in `skills/`
3. Modify agents in `agents/`
4. Commit and push to your fork
5. On new machines, clone your fork and run setup

## Workflow

Once installed, you have access to the feature workflow:

```
Backlog → /pick → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

| Command                | Agent       | Purpose                                    |
| ---------------------- | ----------- | ------------------------------------------ |
| `/pick`                | picker      | Select task from backlog, create blank PRD |
| `/refine user-auth`    | refiner     | Complete and validate PRD                  |
| `/plan user-auth`      | planner     | Create implementation plan                 |
| `/implement user-auth` | implementer | Execute plan on feature branch             |

## Naming Convention

The workflow uses descriptive **slugs** instead of numeric IDs:

| Artifact      | Format           | Example                           |
| ------------- | ---------------- | --------------------------------- |
| Backlog entry | `[slug] Title`   | `[user-auth] User Authentication` |
| PRD file      | `PRD-[slug].md`  | `PRD-user-auth.md`                |
| Plan file     | `PLAN-[slug].md` | `PLAN-user-auth.md`               |
| Branch        | `feat/[slug]`    | `feat/user-auth`                  |

Slugs are:

- Lowercase kebab-case
- Max 30 characters
- Derived from feature name (e.g., "User Authentication" → `user-auth`)

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

## Safety Features

- **Preview before action** - Use `--dry-run` to see what will happen
- **Explicit confirmation** - Asks before overwriting existing files
- **Timestamped backups** - Existing files are backed up as `filename.backup.YYYY-MM-DD`
- **Unlink command** - Easy way to remove symlinks with `./setup.sh unlink`

## Updating

```bash
cd ~/.agentfiles && git pull
```

Since symlinks point to your cloned repo, updates are immediate.
