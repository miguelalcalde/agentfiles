---
name: google-docs
description: >-
  Use when creating, editing, formatting, reviewing, commenting on, or
  suggesting changes in Google Docs. Connector-agnostic: works with whatever
  Docs tools the current harness exposes.
---
# Google Docs

Thin operating rules for Google Docs across harnesses. Use the Docs tools available in this
session.

## Defaults

- Prefer **Markdown** as the draft format for reports and long text. Convert
  into the Doc (or paste structured content) once the substance is settled.
- One Doc = one coherent artifact. Prefer a clear title over a generic
  "Untitled document".
- Do not invent templates unless the user asks for one.

## Create

1. Confirm title (and folder/parent if the user named one).
2. Create the Doc with the harness Docs tools.
3. Put the body in next — headings and lists from the Markdown draft.
4. Return the Doc URL (or id) so the user can open it.

## Format

Map common Markdown to Docs structure:

| Markdown | Doc |
| -------- | --- |
| `#` / `##` / `###` | Heading 1 / 2 / 3 |
| lists | Bulleted or numbered lists |
| `**bold**` / `*italic*` | Bold / italic |
| links | Named links, not raw URLs when a label exists |
| tables | Native Doc tables when the tool supports them; otherwise keep simple lists |

Keep formatting light. Do not decorate for its own sake.

## Edit

- Prefer editing the existing Doc the user pointed at over creating a duplicate.
- Preserve written content you were not asked to change.

## Comments and suggestions

- **Comments** — questions, review notes, blockers. Not a dumping ground for
  the main body.
- **Suggestions** — proposed wording/structure changes for the owner to accept
  or reject.
- Resolve or reply only when that is part of the ask; do not clear others'
  threads unasked.

## Review

When asked to review a Doc:

1. Read the current Doc (not a stale local copy).
2. Check structure, clarity, and whether it matches the brief.
3. Leave comments or suggestions; summarize the top issues in chat.
