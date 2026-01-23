# Feature Workflow Skill

This skill provides a structured workflow for taking features from backlog to implementation.

## Overview

The feature workflow consists of 4 phases:

1. **Pick** - Select a task from the backlog and create a blank PRD
2. **Refine** - Complete the PRD with technical details and acceptance criteria
3. **Plan** - Create a detailed implementation plan with specific tasks
4. **Implement** - Execute the plan on a feature branch

## Agents

| Agent | Purpose | Tools |
|-------|---------|-------|
| `picker` | Select tasks, create PRDs | Read, Write, Glob |
| `refiner` | Complete and validate PRDs | Read, Write, Edit, Grep, Glob |
| `planner` | Create implementation plans | Read, Write, Edit, Grep, Glob, Bash |
| `implementer` | Execute plans, write code | Read, Write, Edit, Grep, Glob, Bash |

## Templates

- `templates/prd-template.md` - PRD document structure
- `templates/plan-template.md` - Implementation plan structure

## Status Flow

### PRD Statuses
```
blank → refined → needs_review → approved
```

### Plan Statuses
```
draft → needs_review → approved → implemented
```

## Usage

Each agent is invoked independently by a human:

```bash
# Pick a task
claude "Use the picker agent to select the next P0 task"

# Refine the PRD
claude "Use the refiner agent on docs/prds/FEAT-001.md"

# Create plan
claude "Use the planner agent for FEAT-001"

# Implement
claude "Use the implementer agent for FEAT-001"
```

## Human Checkpoints

- After **Pick**: Review selected task, adjust if needed
- After **Refine**: Review PRD, mark as `approved` if ready
- After **Plan**: Review plan, mark as `approved` if ready
- After **Implement**: Review code, create PR manually
