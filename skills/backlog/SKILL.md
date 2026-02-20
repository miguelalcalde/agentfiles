---
name: backlog
description: |
  Structured workflow for taking features from backlog to implementation.
  Use when picking tasks, refining PRDs, planning implementation, or implementing features.
  Invokes specialized agents: triager, refiner, planner, implementer, conductor.
---

# Backlog Workflow

A structured workflow for taking features from backlog to implementation using specialized agents.

## Workflow Overview

```
Backlog → /triage → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

**Manual mode**: Each step is human-triggered. Agents do not auto-chain.

**Conductor mode**: Run `/conduct` to orchestrate all phases automatically until complete or blocked.

## Commands

| Command                | Agent       | Purpose                                    |
| ---------------------- | ----------- | ------------------------------------------ |
| `/triage`              | triager     | Select task from backlog, create blank PRD |
| `/refine [slug]`       | refiner     | Complete and validate PRD                  |
| `/plan [slug]`         | planner     | Create implementation plan                 |
| `/implement [slug]`    | implementer | Execute plan on feature branch             |
| `/conduct`             | conductor   | Orchestrate all phases in a loop           |
| `/conduct --phases X`  | conductor   | Run specific phases only (e.g., triage,plan) |
| `/conduct --slug X`    | conductor   | Process specific feature only              |

## Agents

Agents are minimal — they define role, boundaries, and tools. Methodology lives in skills.

| Agent           | Branch       | Writes To                                   | Methodology Skill                |
| --------------- | ------------ | ------------------------------------------- | -------------------------------- |
| **triager**     | main         | `.backlog/prds/`, `.backlog/backlog.md`      | `skills/backlog/triage/SKILL.md` |
| **refiner**     | main         | `.backlog/prds/`                             | `skills/backlog/refine/SKILL.md` |
| **planner**     | main         | `.backlog/plans/`, `.backlog/prds/`          | `skills/backlog/plan/SKILL.md`   |
| **implementer** | feature/*    | Source code                                  | —                                |
| **conductor**   | main + feat  | `.backlog/`, source code, action log         | Orchestrates all of the above    |

## Naming Convention

The workflow uses descriptive **slugs** instead of numeric IDs:

| Artifact      | Format           | Example                           |
| ------------- | ---------------- | --------------------------------- |
| Backlog entry | `[slug] Title`   | `[user-auth] User Authentication` |
| PRD file      | `PRD-[slug].md`  | `PRD-user-auth.md`                |
| Plan file     | `PLAN-[slug].md` | `PLAN-user-auth.md`               |
| Branch        | `feat/[slug]`    | `feat/user-auth`                  |

Slugs: lowercase kebab-case, max 30 characters.

## Status Flow

### PRD Statuses

```
blank → refined → needs_review → approved
```

Only a human sets `approved`. The refiner sets `refined` or `needs_review`.

### Plan Statuses

```
draft → needs_review → approved → implemented
```

Only a human sets `approved`. The planner sets `draft` or `needs_review`.

## Human Checkpoints

- After **Triage**: Review selected task, adjust if needed
- After **Refine**: Review PRD, mark as `approved` if ready
- After **Plan**: Review plan, mark as `approved` if ready
- After **Implement**: Review code, create PR manually

## Project Setup

Each project using this workflow needs a `.backlog/` directory:

```
your-project/
└── .backlog/
    ├── backlog.md
    ├── prds/
    └── plans/
```

## Example Usage

### Manual Mode (step-by-step)

```bash
# Triage the highest priority task
/triage

# Refine a specific PRD
/refine user-auth

# Create implementation plan
/plan user-auth

# Execute the plan
/implement user-auth
```

### Conductor Mode (automated)

```bash
# Run full pipeline until complete or blocked
/conduct

# Run only triage and plan phases
/conduct --phases triage,plan

# Process specific feature only
/conduct --slug user-auth

# Named conductor for parallel operation
/conduct --name frontend --phases triage,plan
```

### Parallel Conductors

Multiple conductors can run in parallel when handling different phases:

```bash
# Terminal 1: Create PRDs and plans
/conduct --name frontend --phases triage,plan

# Terminal 2: Review plans
/conduct --name reviewer --phases refine

# Terminal 3: Implement approved plans
/conduct --name builder --phases implement
```
