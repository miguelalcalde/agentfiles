---
name: next-task
description: |
  Autonomously pick a task from the backlog, plan it, implement it, and commit.
  Use when the user wants to execute the next backlog task end-to-end without interaction.
disable-model-invocation: true
---

# next-task

Autonomous Backlog Task Execution

You are an autonomous coding agent. Your goal is to pick up a task from the backlog, plan it, execute it, and commit the changes — all without human interaction.

**IMPORTANT**: If this project doesn't have a `.backlog/backlog.md` file, halt and request it. Do not assume where tasks are listed. Your first action should be to verify that `.backlog/backlog.md` exists.

## Phase 1: Task Selection

1. Read `.backlog/backlog.md`
2. Find unchecked tasks (`- [ ]`)
3. Select ONE task using these priority criteria (in order):
   - Prefer tasks with clear, unambiguous requirements
   - When in doubt, pick the first qualifying task
4. Sub-items under a bullet are notes, examples, or clarifications — not subtasks

**STOP CONDITIONS** — do NOT proceed if:

- There are no unchecked tasks
- All remaining tasks are ambiguous or require clarification
- The task requires external resources, APIs, or credentials you don't have

## Phase 2: Planning

Before writing any code, follow the planning methodology in `skills/backlog/plan/SKILL.md` with these adjustments for autonomous mode:

1. **Understand the codebase**: Read relevant files to understand the project structure, existing patterns, and where changes belong
2. **Create a lightweight plan** (you may keep it in memory rather than writing a `.backlog/plans/` file):
   - Summary of what the task requires
   - Files to modify or create
   - Step-by-step implementation approach
   - Potential risks or edge cases
   - How you will verify the change
3. **Scope check** — if the task is:
   - Larger than expected (>5 files or >200 lines)
   - Ambiguous in a way that requires human decision
   - Dependent on another incomplete task

   Then STOP, document why, go back to Phase 1, and pick a different task.

## Phase 3: Execution

1. Create a new branch from the current branch with a meaningful name (`feat/[slug]`)
2. Implement changes following:
   - Existing code style and patterns
   - Any coding standards in AGENTS.md, CONTRIBUTING.md, or similar
   - Language-specific best practices
   - Proper error handling
3. After implementation:
   - Run the project's build command (check `package.json`, `Makefile`, or equivalent)
   - Fix any linter errors you introduced
   - Ensure the project compiles without errors
4. **Quality checks**:
   - Verify changes match the task requirements
   - Ensure you haven't broken existing functionality
   - Keep changes minimal and focused

## Phase 4: Update Backlog

After successful implementation:

1. Mark the completed task as done: `- [ ]` → `- [x]`
2. If you completed a sub-task, mark only that sub-task

## Phase 5: Commit

1. **Stage only relevant files**: your code changes and the updated backlog
2. **Commit message format**:

   ```
   feat(<scope>): <short description>

   - <what was done>
   - <another bullet if needed>

   Backlog: <quote or summary of the task>
   ```

3. **Do NOT**: push to remote, force push, amend existing commits, or commit secrets

## Output Summary

```
## Task Completed

**Task**: <task description from backlog>

**Changes Made**:
- <file1>: <what changed>
- <file2>: <what changed>

**Commit**: <commit hash and message summary>

**Verification**: <how you verified it works>

**Notes**: <observations or follow-up items>
```

## Safety Rules

- NEVER delete files unless the task explicitly requires it
- NEVER modify authentication, security, or credential-related code without explicit instruction
- NEVER run destructive commands
- NEVER commit without a successful build
- If something goes wrong, revert your changes and document the issue
- When uncertain, do less rather than more
