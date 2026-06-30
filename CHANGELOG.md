# Changelog

## Unreleased

### Added

- Added `skills/backlog/scripts/backlog-setup.mjs`, an idempotent project setup
  helper that creates missing `.backlog/` scaffold files and upserts the
  canonical GitHub label set from `references/labels.json`.
- Added `skills/backlog/scripts/backlog-sync.mjs`, an optional helper that
  regenerates `.backlog/issues.md` from GitHub Issues via `gh issue list`.
- Added dedupe guidance to `backlog`: verify local `.backlog/` artifacts and
  GitHub Issues before adding inbox items, PRDs, plans, or promoted issues;
  includes overlap signals and resolution rules for exact duplicates, related
  work, and superseded items.
- Added `todoist-api`, a Todoist API v1 reference skill for direct HTTP
  integrations. It documents authentication, endpoint paths, request fields,
  pagination, error handling, and migration caveats without encoding personal
  task-management workflow rules.

### Changed

- Tightened `todoist-api` to API reference only: removed TypeScript client
  helpers from references and replaced `implementation.md` with
  `api-semantics.md` (errors, field semantics, pagination, migration).
- Simplified `backlog` by removing the local GitHub Issues mirror and sync
  helper; promoted work should be checked in GitHub directly. The optional
  `backlog-sync.mjs` helper was restored for projects that want a generated
  read-only snapshot at `.backlog/issues.md`.

### Changed

- Simplified promoted-issue types and GitHub labels: `nitpick`/`chore`/`research`
  are now `type:nit`; status labels are `status:unknown`, `status:ready`, and
  `status:blocked` (replacing `needs-refinement` and `agent-ready`).
- Updated the install target after the repository transfer:

```bash
npx skills add mikemajara/skills --skill backlog
```

- GitHub Issues are now canonical for promoted work. `.backlog/` remains the
  local project memory layer, not a competing task tracker.
- The default backlog structure is now:

```text
.backlog/
  inbox.md
  prds/
  plans/
  memory.md
```

- `.backlog/inbox.md` replaces `.backlog/backlog.md` for rough ideas and tasks
  that are not yet promoted to GitHub Issues.
- `.backlog/memory.md` replaces `.backlog/notes.md` for curated decisions,
  conventions, blockers, gotchas, and durable agent context.
- PRD and plan templates now include an optional `issue` frontmatter field.
- Local PRDs are drafting buffers before GitHub promotion; after promotion,
  delete them or keep a tiny pointer file. GitHub Issues own the canonical
  title, body, status, labels, and discussion—do not maintain duplicate
  editable copies in `.backlog/`.

### Migration Notes

For projects already using an older `.backlog/` layout:

1. Create the new files if they do not exist:

```text
.backlog/inbox.md
.backlog/memory.md
```

2. Rename `.backlog/notes.md` to `.backlog/memory.md` and keep the existing
   human-written content. Add a `## Gotchas` section if it would help future
   agents.
3. Review `.backlog/backlog.md`:
   - Move rough, unpromoted items into `.backlog/inbox.md` under `## Inbox`.
   - Promote trackable work to GitHub Issues.
   - Preserve links from related PRDs and plans to their GitHub Issues.
4. Remove `.backlog/issues.md` if it was only a generated GitHub Issues mirror.
5. Stop manually maintaining `.backlog/backlog.md` once GitHub Issues are
   canonical. Remove or archive it only after confirming its content has moved
   to the inbox, GitHub Issues, PRDs, plans, or memory.

The important invariant is: if an item has a GitHub Issue, GitHub owns its
status.

## 2026-05-23

### Changed

- Updated the install instructions during repository cleanup.
- Documented that this repository publishes a single installable skill named
  `backlog`.
- Kept the repository focused on the `backlog` skill and its minimal
  documentation.

### Removed

- Removed the previous portable agent framework, slash commands, setup script,
  global installer, root backlog scaffold files, and unrelated personal skills.
