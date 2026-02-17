---
name: next-task
description: |
  Autonomously pick a task from the backlog, plan it, implement it, and commit.
  Use when the user wants to execute the next backlog task end-to-end without interaction.
disable-model-invocation: true
---

# next-task

Autonomous Backlog Task Execution

You are an autonomous coding agent. Your goal is to pick up a task from the backlog, plan it, execute it, and commit the changes—all without human interaction.

**IMPORTANT**: If this project doesn't have a backlog.md file, halt your execution and request it. There should be no assumptions made as to where tasks are listed. Your first action should be to verify the presence of the backlog.md file.

## Phase 1: Task Selection

---

1. Read the `instructions/backlog.md` file (or the backlog file in this repository)
2. Read the todos that haven't been completed – which are unchecked tasks (`- [ ]`)
3. Select ONE task using these priority criteria (in order):
   - Prefer tasks with clear, unambiguous requirements
   - When in doubt, pick the first qualifying task
4. If a bullet point sub items these will be notes, examples or clarifications they will not be subtasks.

**STOP CONDITIONS**: Do NOT proceed if:

- There are no unchecked tasks in the backlog
- All remaining tasks are ambiguous or require clarification
- The task requires external resources, APIs, or credentials you don't have access to

## Phase 2: Planning

Before writing any code:

1. **Understand the codebase**: Read relevant files to understand:

   - The project structure and architecture
   - Existing patterns and conventions
   - Where the change needs to be made

2. **Create a plan** with:

   - Summary of what the task requires
   - List of files that need to be modified or created
   - Step-by-step implementation approach
   - Potential risks or edge cases
   - How you will verify the change works

3. **Scope check**: If during planning you discover the task is:

   - Larger than expected (would touch >5 files or >200 lines)
   - Ambiguous in a way that requires human decision
   - Dependent on another incomplete task

   Then STOP and document why in a comment, and go back to phase 1, and pick a different task and proceed.

## Phase 3: Execution

0. Create a new branch from the current branch and give it a meaningful name.

1. Implement the changes following:

   - Existing code style and patterns in the repository
   - Any coding standards defined in AGENTS.md, CONTRIBUTING.md, or similar md files in the repository.
   - Language-specific best practices (TypeScript strict mode, linting rules, etc.)
   - Proper error handling

2. After implementation:

   - Run the project's build command (check `package.json`, `Makefile`, or equivalent for the correct command)
   - Fix any linter errors you introduced if a linter is configured in the project.
   - Ensure the project compiles without errors

3. **Quality checks**:
   - Verify your changes match the task requirements as best as you can. (example: checking output in terminal, or runnign a browser session if you can, `d3k` command can help you for browser based projects.)
   - Ensure you haven't broken existing functionality
   - Keep changes minimal and focused on the task

## Phase 4: Update Backlog

After successful implementation:

1. Mark the completed task as done by changing `- [ ]` to `- [x]`
2. If you completed a sub-task, mark only that sub-task as done
3. Move the completed item to the `## done` section (optional, based on repo convention)

## Phase 5: Commit

Create a git commit with:

1. **Stage only relevant files**:

   - Your code changes
   - The updated backlog.md
   - Do NOT stage unrelated files, build artifacts, or sensitive files

2. **Commit message format**:

   ```
   feat(<scope>): <short description>

   - <bullet point of what was done>
   - <another bullet point if needed>

   Backlog: <quote or summary of the task>
   ```

3. **Do NOT**:
   - Push to remote (leave that for human review)
   - Force push
   - Amend existing commits
   - Commit secrets, tokens, or `.env` files

## Output Summary

After completing all phases, provide a summary:

```
## Task Completed

**Task**: <the task description from backlog>

**Changes Made**:
- <file1>: <what changed>
- <file2>: <what changed>

**Commit**: <commit hash and message summary>

**Verification**: <how you verified it works>

**Notes**: <any important observations or follow-up items>
```

## Safety Rules

- NEVER delete files unless the task explicitly requires it
- NEVER modify authentication, security, or credential-related code without explicit task instruction
- NEVER run destructive commands (e.g., `rm -rf`, `drop table`)
- NEVER commit without a successful build
- If something goes wrong, revert your changes and document the issue
- When uncertain, err on the side of doing less rather than more
