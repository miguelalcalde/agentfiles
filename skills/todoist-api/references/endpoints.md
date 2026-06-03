# Todoist API v1 Endpoints

Authoritative docs: https://developer.todoist.com/api/v1

Base URL:

```text
https://api.todoist.com/api/v1
```

Every endpoint requires:

```text
Authorization: Bearer <token>
```

Use `Content-Type: application/json` for JSON bodies.

## Tasks

| Operation | Method | Path |
| --- | --- | --- |
| List active tasks | `GET` | `/tasks` |
| Get task | `GET` | `/tasks/{task_id}` |
| Create task | `POST` | `/tasks` |
| Update task | `POST` | `/tasks/{task_id}` |
| Delete task | `DELETE` | `/tasks/{task_id}` |
| Move task | `POST` | `/tasks/{task_id}/move` |
| Close task | `POST` | `/tasks/{task_id}/close` |
| Reopen task | `POST` | `/tasks/{task_id}/reopen` |
| Quick Add | `POST` | `/tasks/quick` |
| Filter tasks | `GET` | `/tasks/filter` |
| Completed by completion date | `GET` | `/tasks/completed/by_completion_date` |
| Completed by due date | `GET` | `/tasks/completed/by_due_date` |

Common task query parameters:

- `project_id`
- `section_id`
- `parent_id`
- `label`
- `ids`
- `filter`
- `limit`
- `cursor`

Common task create/update fields:

- `content`: required for create
- `description`
- `project_id`
- `section_id`
- `parent_id`
- `order`
- `labels`: array of label names
- `priority`: integer `1` to `4`; API v1 docs describe `1` as highest
- `assignee_id`
- `deadline_date`
- `duration`: requires `duration_unit` (`minute` or `day`) when set
- `duration_unit`
- `due_string`
- `due_date`
- `due_datetime`
- `due_lang`

Use only one due-date shape unless the API docs explicitly allow a companion
language field. Prefer `due_string` for Todoist natural-language dates and
recurring schedules; prefer `due_date` or `due_datetime` when exact dates are
already known.

Quick Add body:

```json
{
  "text": "Buy milk today #Shopping @groceries p1",
  "note": "Optional comment text",
  "reminder": "tomorrow at 9am",
  "auto_reminder": false,
  "meta": true
}
```

## Projects

| Operation | Method | Path |
| --- | --- | --- |
| List projects | `GET` | `/projects` |
| Search projects | `GET` | `/projects/search` |
| Get project | `GET` | `/projects/{project_id}` |
| Create project | `POST` | `/projects` |
| Update project | `POST` | `/projects/{project_id}` |
| Delete project | `DELETE` | `/projects/{project_id}` |
| Archive project | `POST` | `/projects/{project_id}/archive` |
| Unarchive project | `POST` | `/projects/{project_id}/unarchive` |
| Project collaborators | `GET` | `/projects/{project_id}/collaborators` |

Common project fields:

- `name`
- `description`
- `color`
- `view_style`
- `parent_id`
- `is_favorite`

## Sections

| Operation | Method | Path |
| --- | --- | --- |
| List sections | `GET` | `/sections` |
| Search sections | `GET` | `/sections/search` |
| Get section | `GET` | `/sections/{section_id}` |
| Create section | `POST` | `/sections` |
| Update section | `POST` | `/sections/{section_id}` |
| Delete section | `DELETE` | `/sections/{section_id}` |
| Archive section | `POST` | `/sections/{section_id}/archive` |
| Unarchive section | `POST` | `/sections/{section_id}/unarchive` |

Common section fields:

- `name`
- `project_id`
- `order`

## Labels

| Operation | Method | Path |
| --- | --- | --- |
| List labels | `GET` | `/labels` |
| Search labels | `GET` | `/labels/search` |
| Get label | `GET` | `/labels/{label_id}` |
| Create label | `POST` | `/labels` |
| Update label | `POST` | `/labels/{label_id}` |
| Delete label | `DELETE` | `/labels/{label_id}` |
| List shared labels | `GET` | `/labels/shared` |
| Rename shared label | `POST` | `/labels/shared/rename` |
| Remove shared label occurrences | `POST` | `/labels/shared/remove` |

Common label fields:

- `name`
- `color`
- `order`
- `is_favorite`

Shared-label rename/remove endpoints take label names in the JSON body rather
than in the path.

## Comments

| Operation | Method | Path |
| --- | --- | --- |
| List comments | `GET` | `/comments` |
| Get comment | `GET` | `/comments/{comment_id}` |
| Create comment | `POST` | `/comments` |
| Update comment | `POST` | `/comments/{comment_id}` |
| Delete comment | `DELETE` | `/comments/{comment_id}` |

For listing or creating comments, provide either `task_id` or `project_id`.

## Other Common Resources

- Reminders: `/reminders`, `/reminders/{reminder_id}`
- Location reminders: `/location_reminders`, `/location_reminders/{id}`
- Filters: `/filters`, `/filters/{filter_id}`
- Workspace filters: `/workspace_filters`, `/workspace_filters/{filter_id}`
- Activity logs: `/activities`
- User info: `/user`
- Productivity stats: `/tasks/completed/stats`
- Sync: `/sync`

Use `/sync` for incremental synchronization and command batching. Use the REST
resource endpoints above for ordinary one-off operations.
