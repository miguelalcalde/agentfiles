# Page content — official markdown API

## Endpoint

```http
GET /v1/pages/{page_id}/markdown
Notion-Version: 2026-03-11
Authorization: Bearer {NOTION_TOKEN}
```

SDK:

```typescript
import { Client } from "@notionhq/client"

const notion = new Client({ auth: process.env.NOTION_TOKEN })

const response = await notion.pages.retrieveMarkdown({
  page_id: pageId,
})

const markdown = response.markdown
const truncated = response.truncated
const unknownBlockIds = response.unknown_block_ids
```

## API version

Markdown endpoints require a recent Notion API version. Use `2026-03-11` for
markdown calls. Database query endpoints may use the same version for consistency.

Set on the Client if your SDK version supports it, or pass
`Notion-Version` header on raw fetch calls.

## Response

```typescript
type PageMarkdownResponse = {
  object: "page_markdown"
  id: string
  markdown: string
  truncated: boolean
  unknown_block_ids: string[]
}
```

## Truncation

Very large pages (>~20k blocks) return `truncated: true` and
`unknown_block_ids`. Re-fetch subtrees by passing block ids as `page_id`:

```typescript
for (const blockId of response.unknown_block_ids) {
  const subtree = await notion.pages.retrieveMarkdown({ page_id: blockId })
  // append subtree.markdown
}
```

Most CMS blog posts will not hit this limit.

## Enhanced markdown dialect

Output is Notion-flavored markdown, not plain GFM. Includes standard elements
(headings, lists, code fences, `![caption](url)` images) plus XML-like tags for
Notion-specific blocks. See `enhanced-markdown.md`.

## Images

Image URLs in markdown are pre-signed and expire (~1 hour), same as the block
API. For static sites with long cache windows, use `cache-images.ts` to download
to `public/` at build or first render.

External image URLs (non-Notion-hosted) do not expire.

## Write path (optional)

Notion also supports updating page content via markdown:

```http
PATCH /v1/pages/{page_id}/markdown
```

SDK: `notion.pages.updateMarkdown(...)`. Useful for agent write-back; not
needed for read-only CMS setups.

## Query param

`include_transcript=true` includes meeting note transcripts. Default false shows
a placeholder with meeting URL instead.

## Capability

Requires integration `read_content` capability. Available for internal,
public, and personal access token connections.

## Why not notion-to-md

| Official API | notion-to-md |
|---|---|
| One dependency (@notionhq/client) | Extra package, v4 still alpha |
| First-party maintenance | Third-party block traversal |
| Enhanced markdown dialect | Closer to plain GFM |
| Same image expiry | Built-in download/upload strategies |

Default to official API. Add notion-to-md only if the user needs block-level
custom transformers or already depends on it.
