# Ralphie - Agent-Based Feature Workflow

This repository contains a portable agent system for feature development workflows using Claude Code's native subagent architecture.

## Overview

The workflow uses 4 specialized agents that work in sequence:

1. **Picker** - Selects tasks from the backlog and creates blank PRDs
2. **Refiner** - Completes and validates PRDs with codebase research
3. **Planner** - Creates detailed implementation plans from approved PRDs
4. **Implementer** - Executes plans on feature branches with proper commits

## Directory Structure

- `.claude/agents/` - Agent definitions (markdown with YAML frontmatter)
- `.claude/skills/` - Reusable skills and templates
- `.claude/commands/` - Slash command shortcuts
- `docs/backlog.md` - Feature backlog
- `docs/prds/` - PRD documents (created by agents)
- `docs/plans/` - Implementation plans (created by agents)

## Workflow

```
Backlog → Picker → PRD (blank) → Refiner → PRD (refined) → Planner → Plan → Implementer → Code
```

Each step is human-triggered. Agents do not auto-chain.

## Usage

### Via Slash Commands

```
/pick                    # Pick next task from backlog
/refine FEAT-001         # Refine a specific PRD
/plan FEAT-001           # Create implementation plan
/implement FEAT-001      # Execute plan on feature branch
```

### Via CLI

```bash
claude "Use the picker agent to select the highest priority task"
claude "Use the refiner agent on docs/prds/FEAT-001.md"
claude "Use the planner agent for FEAT-001"
claude "Use the implementer agent for FEAT-001"
```

## Git Workflow

- Agents 0-2 (Picker, Refiner, Planner) work on the **main** branch
- Agent 3 (Implementer) works on **feature branches** (`feature/FEAT-XXX`)
- PRs are created manually after implementation

## Portability

To use this system in another repository:

1. Copy the `.claude/` folder
2. Copy the `docs/` folder structure
3. Customize `docs/backlog.md` with your tasks

## Status Tracking

PRDs and Plans use frontmatter to track status:

- PRD statuses: `blank` → `refined` → `needs_review` → `approved`
- Plan statuses: `draft` → `needs_review` → `approved` → `implemented`
