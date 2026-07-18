# Architecture

## Data flow

```text
notion-ts-client (dev-time)
  notion-sdk.json → notion-sdk/dbs/<db>/
    constants.ts   PROPS_TO_IDS, IDS_TO_PROPS
    types.ts       BlogResponse, typed filters
    db.ts          *Database class (optional at runtime)

Runtime — metadata (list + lookup)
  notion-repository.ts
    → POST /v1/databases/{id}/query  (filter isPublished, sort publishedAt)
    → BlogResponse[]
  notion-flatten.ts
    → FlattenedBlogResponse (plain slug, tags, dates, etc.)
  identity.ts
    → matchesSlug(), normalizePageSlug()

Runtime — page body
  markdown/fetch.ts
    → notion.pages.retrieveMarkdown({ page_id })
    → response.markdown (enhanced markdown string)
  markdown/rewrite-links.ts
    → Notion URLs + <page> tags → /{route}/{slug}
  markdown/cache-images.ts (optional)
    → download expiring URLs → public/notion-media/
  mdx.ts
    → next-mdx-remote compile → React

Next.js
  /{route}           index from flattened metadata
  /{route}/[slug]    detail: metadata header + MDX body
  /{route}/[slug]/md optional raw markdown
```

## Why two Notion tools

- **notion-ts-client** answers: what properties exist on each CMS entry, with
  compile-time types and stable property-id mapping for queries.
- **retrieveMarkdown** answers: what is the page body content, in one API call.

Neither replaces the other.

## Why raw fetch for database queries

The generated `*Database` class (from notion-ts-client) wraps query/getPage/CRUD
with rate limiting. Many Next.js CMS projects use raw `fetch` instead because:

- No extra runtime coupling to generated class constructors
- Same property-id constants either way
- Easy to read in RSC server components

Both are valid. Default this skill to raw fetch + generated constants. Offer
`*Database` when the project needs write-back or block CRUD.

## File layout (typical)

```text
notion-sdk.json
notion-sdk/                    generated, do not hand-edit
src/lib/writings/              rename to match feature (docs, blog, etc.)
  config.ts
  identity.ts
  notion-repository.ts
  notion-flatten.ts
  service.ts
  markdown/
    fetch.ts
    rewrite-links.ts
    cache-images.ts
src/lib/mdx.ts
src/app/writings/
  page.tsx
  [slug]/page.tsx
  [slug]/data.ts
  [slug]/md/route.ts
```

## tsconfig note

Some projects exclude `notion-sdk/` from `tsconfig.json` `exclude` but import
via relative paths (`../../../notion-sdk/...`). Either:

- Keep excluded and use relative imports (nblog pattern), or
- Include `notion-sdk` and add a path alias

Pick one per project; do not mix approaches.
