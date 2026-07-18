# Database queries

## Query published pages

Use generated `PROPS_TO_IDS` for filter and sort property keys.

```typescript
const filter = includeUnpublished
  ? undefined
  : {
      property: BLOG_PROPS_TO_IDS.isPublished,
      checkbox: { equals: true },
    }

const response = await fetch(
  `https://api.notion.com/v1/databases/${databaseId.replaceAll("-", "")}/query`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${getNotionToken()}`,
      "Notion-Version": NOTION_API_VERSION,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      filter,
      sorts: [
        {
          property: BLOG_PROPS_TO_IDS.publishedAt,
          direction: "descending",
        },
      ],
      page_size: limit,
      start_cursor: startCursor,
    }),
  },
)
```

Cast `results` to `BlogResponse[]` after validating `object === "page"`.

## Flatten properties

Notion returns nested property objects (`rich_text`, `multi_select`, `formula`,
etc.). Flatten to plain values the UI can consume:

```typescript
type Flattened = {
  id: string
  name: string
  slug: string | null
  isPublished: boolean
  publishedAt: Date | null
  tags: string[]
  summary: string
}
```

Generic helper pattern:

1. `IDS_TO_PROPS` maps property id → varName
2. Switch on `property.type` to extract value
3. Merge onto response object

See `assets/templates/src-lib/notion-flatten.ts`.

## Find by slug

Notion has no slug filter unless you store slug as a queryable field. Paginate
the full published set and match client-side:

```typescript
do {
  const { pages, nextCursor } = await queryPublishedPages({ startCursor: cursor })
  for (const page of pages) {
    if (matchesSlug(flattenBlogResponse(page), slug)) return flattened
  }
  cursor = nextCursor
} while (cursor)
```

`matchesSlug` should accept both formula slug and raw page id (uuid with or
without dashes).

## Unpublished preview

Gate with env flag for local preview:

```typescript
const includeUnpublished = process.env.SHOW_UNPUBLISHED === "true"
```

When true, omit the `isPublished` filter. Never enable in production unless
intentional.

## Pagination

Database query returns `next_cursor`. Loop for full exports; for slug lookup
use `page_size: 100` per request.

## Alternative: generated Database class

```typescript
const db = new BlogDatabase({ notionSecret: token })
const { results } = await db.query({
  filter: { isPublished: { equals: true } },
  sorts: [{ property: "publishedAt", direction: "descending" }],
  page_size: limit,
})
```

Typed filters use varNames (`isPublished`), not Notion display names. Class
handles id remapping internally.
