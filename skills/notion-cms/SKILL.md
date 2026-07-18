---
name: notion-cms
description: |
  Set up Notion as a CMS in Next.js App Router apps using notion-ts-client
  (typed database SDK generation) and the official Notion markdown API
  (pages.retrieveMarkdown). Use when scaffolding a Notion-backed site, adding a
  new Notion database to a Next.js project, regenerating notion-sdk after schema
  changes, querying database metadata, rendering Notion page content as MDX, or
  wiring slug routes and internal link rewriting.
---

# Notion CMS (Next.js)

Use this skill to bootstrap a Notion-backed content site in Next.js.

## Stack decision

Use two tools with separate jobs:

| Layer | Tool | Job |
|---|---|---|
| Database metadata | **notion-ts-client** | Generate typed SDK from Notion DB schema |
| Page body | **@notionhq/client** `pages.retrieveMarkdown` | Fetch page content as markdown |

Do **not** add `notion-to-md` unless the user explicitly asks. The official
markdown endpoint is simpler, already a project dependency, and sufficient for
Next.js CMS setups.

`notion-ts-client` gives compile-time knowledge of database properties.
`retrieveMarkdown` gives page body content. They are complementary.

## Prerequisites

1. Create a Notion integration at https://www.notion.so/my-integrations
2. Copy the integration secret token
3. In Notion, connect each CMS database to the integration
   (`...` → Add connections → your integration)
4. Design the CMS database with at least:
   - `name` (title)
   - `slug` (formula or rich_text)
   - `isPublished` (checkbox)
   - `publishedAt` (date)
   - `summary` or `description` (rich_text) for index cards

See `references/notion-schema.md` for a full property checklist.

## Phase 1 — Generate typed SDK

```bash
npx notion-ts-client@latest init --secret "$NOTION_TOKEN"
```

Edit the generated config (`notion-sdk.json` by default):

- Set `varName` and `pathName` per database (e.g. `blog`, `blog`)
- Rename property `varName` values to camelCase API names (`metaTitle`, `isPublished`)
- Mark system fields `readOnly: true` (`createdAt`, `editedAt`)

```bash
npx notion-ts-client@latest generate --sdk ./notion-sdk
```

Add npm scripts:

```json
{
  "scripts": {
    "notion:init": "npx notion-ts-client@latest init",
    "notion:generate": "npx notion-ts-client@latest generate"
  }
}
```

Commit `notion-sdk.json`. Treat `notion-sdk/` as generated output — regenerate,
do not hand-edit.

Details: `references/notion-ts-client.md`

## Phase 2 — Environment

Copy `assets/templates/env.example` to `.env.local`:

```bash
NOTION_TOKEN=secret_...
NOTION_TS_CLIENT_CONFIG_PATH=./notion-sdk.json
NOTION_TS_CLIENT_SDK_PATH=./notion-sdk
NOTION_TS_CLIENT_NOTION_SECRET=secret_...
NOTION_BLOG_DATABASE_ID=your-database-uuid
```

`NOTION_TOKEN` is runtime auth. `NOTION_TS_CLIENT_*` vars are for CLI generation.

## Phase 3 — Install runtime deps

```bash
pnpm add @notionhq/client next-mdx-remote remark-gfm rehype-slug rehype-autolink-headings
```

Dev-time only (no package.json entry needed): `npx notion-ts-client@latest`

Use `NOTION_API_VERSION=2026-03-11` for markdown endpoints. See
`references/page-content.md`.

## Phase 4 — Lib layer

Create `src/lib/<feature>/` using templates in `assets/templates/src-lib/`.
Adapt `{{FEATURE}}`, `{{ROUTE_PREFIX}}`, and `{{DATABASE_VAR}}` to the project.

| File | Role |
|---|---|
| `config.ts` | Token, database ID, API version |
| `identity.ts` | Slug normalization, id/slug matching |
| `notion-repository.ts` | Query published pages via raw fetch + generated `PROPS_TO_IDS` |
| `notion-flatten.ts` | Map nested Notion properties → plain values |
| `service.ts` | Orchestrate list, lookup, markdown fetch, link rewrite |
| `markdown/fetch.ts` | `pages.retrieveMarkdown` wrapper |
| `markdown/rewrite-links.ts` | Rewrite Notion URLs and `<page>` tags to internal routes |
| `markdown/cache-images.ts` | Optional: download expiring image URLs to `public/` |

**Query pattern:** import `*_PROPS_TO_IDS` and `*Response` types from
`notion-sdk/dbs/<db>/`. Query with raw `fetch` to the Notion database query API
using property IDs from constants. The generated `*Database` class is available
but optional.

Details: `references/database-queries.md`, `references/architecture.md`

## Phase 5 — Next.js routes

Typical App Router layout:

```text
src/app/{{ROUTE_PREFIX}}/
  page.tsx                  # index — list from database metadata
  [slug]/
    page.tsx                # detail — metadata + MDX body
    data.ts                 # re-export service functions
    md/route.ts             # optional raw markdown endpoint
```

Index page: call `fetchPublishedPosts(limit)`, map to card props, render list.

Detail page:

```typescript
const page = await fetchPageBySlug(slug)
const markdown = await fetchPageMarkdownByPageId(page.id)
const content = await renderMdx(markdown)
```

Set `revalidate` (e.g. 300 for index, 86400 for posts). Add
`generateStaticParams` for prebuild:

```typescript
export async function generateStaticParams() {
  const posts = await fetchPrerenderPosts(20)
  return posts.map((p) => ({ slug: normalizePageSlug(p.slug) || p.id }))
}
```

Copy `assets/templates/app-routes/` and adapt paths.

## Phase 6 — MDX rendering

Use `next-mdx-remote/rsc` with remark-gfm and rehype plugins. Copy
`assets/templates/mdx.ts` and wire custom components as needed.

Enhanced markdown from Notion may include XML-like tags (`<page>`, `<callout>`).
Most tags pass through as unknown HTML or can be handled with custom MDX
components later. See `references/enhanced-markdown.md`.

## Phase 7 — Link rewriting

After `retrieveMarkdown`, run link rewriting before MDX compile:

1. Standard markdown links pointing at `notion.so` / `notion.site` → internal routes
2. Enhanced tags: `<page url="...">Title</page>` → `[Title](/route/slug)`
3. `<mention-page url="...">` → same treatment

Resolver looks up published pages by Notion page id and returns `{ href, title }`.
Template: `assets/templates/src-lib/markdown/rewrite-links.ts`

## Phase 8 — Images (optional)

Notion image URLs expire (~1 hour). For static sites, cache on first render:

1. Scan markdown for `![...](https://...notion-static.com/...)`
2. Download to `public/notion-media/<hash>.<ext>` if not cached
3. Replace URL in markdown with `/notion-media/<hash>.<ext>`

Template: `assets/templates/src-lib/markdown/cache-images.ts`

Skip this unless the project has many uploaded images or uses long `revalidate`
windows with static export.

## Phase 9 — Schema changes

When Notion database properties change:

```bash
pnpm notion:generate
```

Fix TypeScript errors from changed select options or property types. Regenerated
constants (`PROPS_TO_IDS`) keep queries working across property renames.

## Regeneration checklist

- [ ] Integration connected to database in Notion
- [ ] `notion-sdk.json` varNames reviewed
- [ ] `pnpm notion:generate` run
- [ ] `NOTION_TOKEN` in `.env.local`
- [ ] `src/lib/<feature>/` layer created from templates
- [ ] App routes wired with `revalidate` + `generateStaticParams`
- [ ] Link rewriter configured with correct `ROUTE_PREFIX`
- [ ] MDX pipeline renders a test page end-to-end

## References

- `references/architecture.md` — data flow and file map
- `references/notion-ts-client.md` — init, generate, config JSON
- `references/database-queries.md` — query, flatten, slug lookup
- `references/page-content.md` — retrieveMarkdown, truncation, API version
- `references/enhanced-markdown.md` — Notion-flavored markdown dialect
- `references/notion-schema.md` — recommended database properties

## Templates

Copy and adapt files under `assets/templates/`:

- `env.example`
- `src-lib/` — lib layer
- `app-routes/` — Next.js pages
- `mdx.ts` — MDX compile helper
