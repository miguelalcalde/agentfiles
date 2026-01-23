# Ralphie

A portable agent-based feature workflow system for Claude Code.

## What is this?

Ralphie provides a structured workflow for taking features from backlog to implementation using 4 specialized AI agents:

| Agent           | Purpose                                        | Color  |
| --------------- | ---------------------------------------------- | ------ |
| **Picker**      | Selects tasks from backlog, creates blank PRDs | Blue   |
| **Refiner**     | Completes PRDs with technical details          | Yellow |
| **Planner**     | Creates detailed implementation plans          | Orange |
| **Implementer** | Executes plans on feature branches             | Green  |

## Workflow

```
Backlog → Picker → PRD (blank) → Refiner → PRD (refined) → Planner → Plan → Implementer → Code
           ↑          ↑              ↑           ↑              ↑          ↑              ↑
         Human      Human          Human       Human          Human      Human          Human
```

Each step is human-triggered. Agents do not auto-chain.

## Quick Start

### 1. Add tasks to the backlog

Edit `docs/backlog.md`:

```markdown
### [FEAT-003] My New Feature

- **Priority**: P0 (Critical)
- **Status**: pending
- **Description**: Brief description of the feature
- **Why**: Business justification
- **PRD**:
- **Plan**:
```

### 2. Pick a task

```bash
# Via slash command
/pick

# Or via CLI
claude "Use the picker agent to select the highest priority task"
```

### 3. Refine the PRD

```bash
/refine FEAT-003

# Or
claude "Use the refiner agent on docs/prds/FEAT-003.md"
```

Review the PRD and mark as `approved` when ready.

### 4. Create implementation plan

```bash
/plan FEAT-003

# Or
claude "Use the planner agent for FEAT-003"
```

Review the plan and mark as `approved` when ready.

### 5. Implement the feature

```bash
/implement FEAT-003

# Or
claude "Use the implementer agent for FEAT-003"
```

Review the code and create a PR manually.

## Directory Structure

```
.claude/
├── settings.json              # Claude Code settings
├── CLAUDE.md                  # Project instructions
├── agents/
│   ├── picker.md              # Task Picker agent
│   ├── refiner.md             # PRD Refiner agent
│   ├── planner.md             # Implementation Planner agent
│   └── implementer.md         # Feature Implementer agent
├── skills/
│   └── feature-workflow/
│       ├── SKILL.md           # Skill definition
│       └── templates/
│           ├── prd-template.md
│           └── plan-template.md
└── commands/
    ├── pick.md                # /pick command
    ├── refine.md              # /refine command
    ├── plan.md                # /plan command
    └── implement.md           # /implement command

docs/
├── backlog.md                 # Feature backlog
├── prds/                      # PRD documents
└── plans/                     # Implementation plans
```

## Status Flow

### PRD Statuses

```
blank → refined → needs_review → approved
```

### Plan Statuses

```
draft → needs_review → approved → implemented
```

## Git Workflow

- Agents 0-2 (Picker, Refiner, Planner) work on **main** branch
- Agent 3 (Implementer) works on **feature branches** (`feature/FEAT-XXX`)
- PRs are created manually after implementation

## Using in Your Project

To add Ralphie to an existing project:

1. **Copy the `.claude/` folder** to your project root
2. **Copy the `docs/` folder** structure
3. **Customize `docs/backlog.md`** with your tasks
4. **Update `.claude/CLAUDE.md`** with project-specific context

That's it! The agents will work with your codebase.

## Customization

### Modifying Agent Behavior

Edit the markdown files in `.claude/agents/`. Each agent has:

- **Frontmatter**: name, description, tools, color
- **Body**: detailed instructions, rules, process

### Adding Custom Commands

Create new `.md` files in `.claude/commands/` with:

```yaml
---
description: What the command does
arguments:
  - name: arg_name
    description: Argument description
    required: true
---
Instructions for the command...
Use $ARGUMENTS.arg_name to reference arguments.
```

### Modifying Templates

Edit templates in `.claude/skills/feature-workflow/templates/` to match your PRD and plan formats.

## License

MIT
