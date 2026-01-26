---
name: feature-workflow
description: |
  Structured workflow for taking features from backlog to implementation.
  Use when picking tasks, refining PRDs, planning implementation, or implementing features.
  Invokes specialized agents: picker, refiner, planner, implementer.
---

# Feature Workflow

A structured workflow for taking features from backlog to implementation using 4 specialized agents.

## Workflow Overview

```
Backlog → /pick → PRD → /refine → PRD (refined) → /plan → Plan → /implement → Code
```

Each step is human-triggered. Agents do not auto-chain.

## Commands

| Command                | Agent       | Purpose                                    |
| ---------------------- | ----------- | ------------------------------------------ |
| `/pick`                | picker      | Select task from backlog, create blank PRD |
| `/refine [slug]`       | refiner     | Complete and validate PRD                  |
| `/plan [slug]`         | planner     | Create implementation plan                 |
| `/implement [slug]`    | implementer | Execute plan on feature branch             |

## Agents

| Agent           | Branch       | Writes To                  | Tools                              |
| --------------- | ------------ | -------------------------- | ---------------------------------- |
| **picker**      | main         | `docs/prds/`, `backlog.md` | Read, Write, Glob                  |
| **refiner**     | main         | `docs/prds/`               | Read, Write, Edit, Grep, Glob      |
| **planner**     | main         | `docs/plans/`, `docs/prds/`| Read, Write, Edit, Grep, Glob      |
| **implementer** | feature/*    | Source code                | Read, Write, Edit, Grep, Glob, Bash|

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

### Plan Statuses

```
draft → needs_review → approved → implemented
```

## Human Checkpoints

- After **Pick**: Review selected task, adjust if needed
- After **Refine**: Review PRD, mark as `approved` if ready
- After **Plan**: Review plan, mark as `approved` if ready
- After **Implement**: Review code, create PR manually

## Templates

- [PRD Template](templates/prd-template.md) - Structure for Product Requirements Documents
- [Plan Template](templates/plan-template.md) - Structure for Implementation Plans

## Project Setup

Each project using this workflow needs a `docs/` folder:

```
your-project/
└── docs/
    ├── backlog.md
    ├── prds/
    └── plans/
```

## Example Usage

```bash
# Pick the highest priority task
/pick

# Refine a specific PRD
/refine user-auth

# Create implementation plan
/plan user-auth

# Execute the plan
/implement user-auth
```
