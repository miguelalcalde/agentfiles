# Ralphie

Portable agents for Claude Code and Cursor.

## Install

```bash
npx ralphie
```

This will interactively guide you through:

1. Choosing install location (global, local project, or custom path)
2. Selecting which tools (Claude Code, Cursor, or both)
3. Previewing changes before they're made
4. Backing up any existing files

## Commands

```bash
npx ralphie                     # Interactive install (default)
npx ralphie install             # Same as above
npx ralphie install --global    # Install to ~/.claude, ~/.cursor
npx ralphie install --local     # Install to ./.claude, ./.cursor
npx ralphie install --path /foo # Install to custom path
npx ralphie install --dry-run   # Preview only, no changes
npx ralphie install --claude    # Claude Code only
npx ralphie install --cursor    # Cursor only

npx ralphie status              # Show what's installed where
npx ralphie unlink              # Remove symlinks
```

## What Gets Installed

The following symlinks are created in your chosen location:

```
.claude/
├── agents/     -> ralphie/agents
├── commands/   -> ralphie/commands
├── skills/     -> ralphie/skills
└── settings.json -> ralphie/settings/claude.json

.cursor/
├── agents/     -> ralphie/agents
├── commands/   -> ralphie/commands
└── skills/     -> ralphie/skills
```

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

- **Preview before action** - Always shows what will happen before making changes
- **Explicit confirmation** - Requires confirmation before overwriting existing files
- **Timestamped backups** - Existing files are backed up as `filename.backup.YYYY-MM-DD`
- **Unlink command** - Easy way to remove symlinks if needed
