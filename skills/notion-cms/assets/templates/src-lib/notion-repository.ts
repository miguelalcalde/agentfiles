import { BLOG_PROPS_TO_IDS } from "../../../notion-sdk/dbs/blog/constants"
import type { BlogResponse } from "../../../notion-sdk/dbs/blog/types"

import { BLOG_DATABASE_ID, getNotionToken, NOTION_API_VERSION } from "./config"
import { flattenBlogResponse, type FlattenedBlogResponse } from "./notion-flatten"
import { matchesSlug } from "./identity"

type QueryResult = {
  pages: BlogResponse[]
  nextCursor?: string
}

const databaseQueryUrl = (databaseId: string): string =>
  `https://api.notion.com/v1/databases/${databaseId.replaceAll("-", "")}/query`

export const queryPublishedPages = async ({
  limit,
  startCursor,
  includeUnpublished = false,
}: {
  limit?: number
  startCursor?: string
  includeUnpublished?: boolean
}): Promise<QueryResult> => {
  const filter = includeUnpublished
    ? undefined
    : {
        property: BLOG_PROPS_TO_IDS.isPublished,
        checkbox: { equals: true },
      }

  const response = await fetch(databaseQueryUrl(BLOG_DATABASE_ID), {
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
  })

  if (!response.ok) {
    throw new Error(`Notion query failed: ${response.status}`)
  }

  const data = (await response.json()) as {
    results?: unknown[]
    next_cursor?: string | null
  }

  const pages = (data.results ?? []).filter(
    (r): r is BlogResponse =>
      Boolean(r && typeof r === "object" && (r as BlogResponse).object === "page"),
  )

  return {
    pages,
    nextCursor: data.next_cursor ?? undefined,
  }
}

export const fetchPublishedPosts = async (
  limit: number,
  { includeUnpublished = false } = {},
): Promise<FlattenedBlogResponse[]> => {
  const { pages } = await queryPublishedPages({ limit, includeUnpublished })
  return pages.map(flattenBlogResponse)
}

export const findPageBySlug = async (
  slug: string,
  { includeUnpublished = false } = {},
): Promise<FlattenedBlogResponse | null> => {
  let cursor: string | undefined

  do {
    const { pages, nextCursor } = await queryPublishedPages({
      limit: 100,
      startCursor: cursor,
      includeUnpublished,
    })

    for (const page of pages) {
      const flat = flattenBlogResponse(page)
      if (matchesSlug(flat, slug)) return flat
    }

    cursor = nextCursor
  } while (cursor)

  return null
}
