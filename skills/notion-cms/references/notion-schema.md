# Recommended CMS database schema

Minimum properties for a Next.js content site backed by one Notion database.

## Required

| varName | Notion type | Purpose |
|---|---|---|
| `name` | title | Display title (Notion's built-in title column) |
| `slug` | formula or rich_text | URL segment; formula from title is common |
| `isPublished` | checkbox | Gate public visibility |
| `publishedAt` | date | Sort order, display date |

## Recommended

| varName | Notion type | Purpose |
|---|---|---|
| `summary` | rich_text | Short card blurb for index |
| `description` | rich_text | Longer excerpt or subtitle |
| `tags` | multi_select | Filtering on index page |
| `metaTitle` | rich_text | SEO title override |
| `metaSummary` | rich_text | SEO description |
| `author` | rich_text | Byline |
| `locale` | select | i18n if needed |
| `createdAt` | created_time | readOnly — audit |
| `editedAt` | last_edited_time | readOnly — "last edited" label |

## Optional

| varName | Notion type | Purpose |
|---|---|---|
| `series` | select | Group related posts |
| `related` | relation | Link to other CMS pages |
| `archive` | checkbox | Soft-hide without deleting |
| `isProtected` | checkbox | Future auth gate |

## Slug formula example

In Notion, a formula slug often lowercases and hyphenates the title:

```notion
replaceAll(lower(prop("name")), " ", "-")
```

Or authors maintain slug manually in a rich_text field.

## Page body

Page body lives in Notion blocks on the database row (the page itself), not in
a property. Fetched via `retrieveMarkdown`, not database query.

## Multiple databases

`notion-ts-client` can generate SDKs for several databases (e.g. `blog`,
`content`, `postDb`). Start with one CMS database per content type. Add others
when the project needs distinct schemas or routes.
