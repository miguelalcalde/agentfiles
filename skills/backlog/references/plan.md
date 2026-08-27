# Plan (product spec)

A plan is the product spec for **one issue**. It is what used to be called a PRD. It is **not** an implementation sequence.

## Done when

A competent implementer would not invent product behavior. In scope and out of scope are explicit. Acceptance criteria are testable. Open questions are listed or there are none.

**A plan does not include:** file paths, APIs, schemas, task order, or “how we will implement.” If those appear, they are not the plan — strip them or the work is still in refine.

If the document is too big for one first change, it is not done: **split issues**.

## When to use a file

Prefer the **issue body** as the plan. Use `.backlog/plans/PLAN-[slug].md` only as a draft buffer when the spec is long; fold it into the issue (or leave a pointer) when refine finishes. After that, the issue is canonical.

Skip a separate plan when the issue already meets this bar (`plan skipped: <reason>`).

## Template

```markdown
---
slug: [slug]
title: [title]
status: draft
issue: [issue URL or blank]
created_at: [ISO-8601]
---

# [Title]

## Problem

## Goal

## In scope

## Out of scope

## Acceptance criteria

- [ ]

## Open questions
```

File statuses: `draft` → `ready` (folded into the issue) → delete or pointer. Pointer:

```markdown
---
slug: [slug]
status: promoted
issue: [issue URL]
promoted_at: [ISO-8601]
---

Canonical spec is GitHub Issue #[number].
```
