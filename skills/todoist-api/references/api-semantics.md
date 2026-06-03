# Todoist API v1 Semantics

Authoritative docs: https://developer.todoist.com/api/v1

## Pagination

Cursor-based lists return `results` and `next_cursor`. When `next_cursor` is `null`,
there are no more pages.

- `limit`: optional page size (default `50`, max `200` per official docs)
- `cursor`: opaque token from the previous response's `next_cursor`

Keep `limit`, filters, and other query parameters identical across cursor requests.
Do not parse or modify cursor strings.

```bash
# First page
curl -s "https://api.todoist.com/api/v1/tasks?limit=100" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"

# Next page (use next_cursor value from prior response)
curl -s "https://api.todoist.com/api/v1/tasks?limit=100&cursor=CURSOR_FROM_RESPONSE" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

## Errors

Standard HTTP status codes:

- `400`: invalid field, malformed filter, stale placeholder ID, or bad date
- `401`: missing, expired, revoked, or malformed token
- `403`: token lacks scope or the account plan does not allow the feature
- `404`: resource ID not found or not accessible to this principal
- `429`: rate limit; back off and retry if the operation is safe
- `5xx`: transient server failure; retry idempotent reads

API v1 error bodies are JSON (not plain text), for example:

```json
{
  "error": "Task not found",
  "error_code": 478,
  "error_extra": {"event_id": "<hash>", "retry_after": 3},
  "error_tag": "NOT_FOUND",
  "http_code": 404
}
```

Never log or echo the API token while debugging.

## IDs

Use server resource IDs from API v1 responses. Do not call REST endpoints with
client-side optimistic IDs that start with `tmp-`; wait for sync to resolve the
real ID.

Legacy REST v2 and Sync v9 examples may mention numeric IDs, `v2_id`, or old
field names. Treat those as migration context, not current API shape.

## Due Dates

Use one due shape per task unless the docs explicitly allow a companion language
field:

- `due_string`: natural language, recurring schedules, Todoist parser behavior
- `due_date`: all-day date (`YYYY-MM-DD`)
- `due_datetime`: exact datetimes
- `due_lang`: language hint when using due fields that support it
- `deadline_date`: deadlines (`YYYY-MM-DD`), not ordinary due dates

Do not put due-date text in `description` when a due field is available.

## Priority

`priority` is an integer from `1` to `4`; `1` is highest per API v1 task docs.

Quick Add text uses Todoist syntax (`p1` to `p4`). Do not copy old REST v2
guidance that inverts priority without checking current official docs.

## Task Create vs Quick Add

- **Explicit create**: `POST /tasks` with `content` (required) and optional fields
  such as `project_id`, `labels`, `priority`, `due_string`.
- **Quick Add**: `POST /tasks/quick` with `text` (required) for natural-language
  parsing (`#Project`, `/Section`, `@label`, `p1`–`p4`, reminders, ` // ` notes).
  Optional body fields: `note`, `reminder`, `auto_reminder`, `meta`.

## Completed Tasks

Active task lists do not include completed tasks. Use:

- `GET /tasks/completed/by_completion_date`
- `GET /tasks/completed/by_due_date`
- `GET /sync` when incremental sync state is needed

## Migration Caveats

Todoist API v1 unified prior REST v2 and Sync v9 surfaces:

- Current paths live under `/api/v1`, not `/rest/v2`.
- Endpoints are lowercase; mixed casing is rejected.
- Many list endpoints are cursor-paginated with `results` and `next_cursor`.
- Some object fields were renamed; re-read current docs when porting examples.
- Quick Add is `POST /tasks/quick`, not the old Sync quick-add path.
