---
name: todoist-api
description: |
  Todoist API v1 integration reference. Use when building or operating code,
  tools, scripts, or agents that call Todoist directly over HTTP for tasks,
  projects, sections, labels, comments, reminders, filters, completed-task
  history, sync, or Quick Add. Prefer this for API mechanics, endpoint shapes,
  authentication, pagination, and migration caveats; keep product workflow and
  task-management preferences in the calling agent's own instructions.
---

# Todoist API

Use this skill to call Todoist's current unified API v1 directly.

This skill is API reference only. Do not decide task workflow, default projects,
default due dates, confirmation policy, or personal task-management conventions
from this skill. Read those from the calling agent's instructions or the user.

## Core Rules

- Use `https://api.todoist.com/api/v1` as the base URL.
- Do not use stale `/rest/v2` examples unless the user explicitly asks for a
  legacy integration.
- Authenticate every request with `Authorization: Bearer $TODOIST_API_TOKEN` or
  an OAuth access token.
- Send JSON request bodies with `Content-Type: application/json`.
- Treat official docs as authoritative when they differ from third-party skills,
  SDK examples, or old REST/Sync examples.
- Keep token values out of logs, generated files, task descriptions, and error
  messages.

## Auth

For personal automation, read `TODOIST_API_TOKEN` from the environment:

```bash
curl -s "https://api.todoist.com/api/v1/tasks?limit=50" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

For multi-user apps, use OAuth and request the smallest scopes needed:

- `task:add`: add new tasks only
- `data:read`: read tasks, projects, labels, filters, and related data
- `data:read_write`: read and write application data
- `data:delete`: delete tasks, labels, filters, and related data
- `project:delete`: delete projects

## Task Creation

Use explicit task creation when the caller already knows fields:

```bash
curl -s -X POST "https://api.todoist.com/api/v1/tasks" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Review launch checklist",
    "description": "Confirm owners and dates",
    "project_id": "PROJECT_ID",
    "labels": ["planning"],
    "priority": 1,
    "due_string": "tomorrow"
  }'
```

Use Quick Add when the caller wants Todoist natural-language parsing:

```bash
curl -s -X POST "https://api.todoist.com/api/v1/tasks/quick" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Review launch checklist tomorrow #Work @planning p1",
    "meta": true
  }'
```

Quick Add supports project markers (`#Project`), section markers (`/Section`),
labels (`@label`), priorities (`p1` to `p4`), deadlines in braces, reminders,
assignees, and trailing descriptions after ` // `.

## Pagination

Paginated endpoints return:

```json
{
  "results": [],
  "next_cursor": null
}
```

Loop until `next_cursor` is `null`. Keep the same filters and `limit` across
cursor requests. Do not parse or modify cursor strings. Default page size is
`50`; maximum `limit` is `200` per official docs.

Official reference: https://developer.todoist.com/api/v1

## References

- Read `references/endpoints.md` for endpoint paths and common request fields.
- Read `references/api-semantics.md` for pagination, errors, field semantics,
  completed-task access, and migration caveats.
