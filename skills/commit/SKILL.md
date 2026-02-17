---
name: commit
description: |
  Generate conventional commit messages by analyzing staged or unstaged git changes.
  Use when the user asks to commit, write a commit message, or prepare changes for commit.
disable-model-invocation: true
---

# commit


ROLE: You are an expert developer
Your task is to study and understand the changes that the user is going to commit, and write up a commit based on the spec below: Conventional commits 1.0.0

Edge cases: 
1. If there are no files staged, assume all changes will be commited.
2. If changes are staged, make sure the commit only references the commited files.

## Spec Reference

For the full Conventional Commits 1.0.0 specification, see [conventional-commits.md](conventional-commits.md).
