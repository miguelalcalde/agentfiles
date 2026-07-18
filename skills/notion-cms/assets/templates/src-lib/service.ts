import { Client } from "@notionhq/client"

import { getNotionToken } from "./config"
import { normalizePageSlug } from "./identity"
import type { FlattenedBlogResponse } from "./notion-flatten"
import {
  fetchPublishedPosts,
  findPageBySlug,
} from "./notion-repository"
import { cacheNotionImagesInMarkdown } from "./markdown/cache-images"
import { fetchPageMarkdown } from "./markdown/fetch"
import { rewriteNotionLinks } from "./markdown/rewrite-links"

const includeUnpublished = (): boolean =>
  process.env.SHOW_UNPUBLISHED === "true"

export const fetchPublishedBlogPosts = (limit: number) =>
  fetchPublishedPosts(limit, { includeUnpublished: includeUnpublished() })

export const fetchPageBySlug = (slug: string) =>
  findPageBySlug(slug, { includeUnpublished: includeUnpublished() })

export const fetchPageMarkdownByPageId = async (
  pageId: string,
  { cacheImages = false } = {},
): Promise<string> => {
  const notion = new Client({ auth: getNotionToken() })
  let markdown = await fetchPageMarkdown(pageId)

  markdown = await rewriteNotionLinks(markdown, notion, async (id) => {
    const page = await findPageBySlug(id, {
      includeUnpublished: includeUnpublished(),
    })
    if (!page) return null
    const href = `/writings/${normalizePageSlug(page.slug) || page.id}`
    return { href, title: page.name.trim() || "Untitled" }
  })

  if (cacheImages) {
    markdown = await cacheNotionImagesInMarkdown(markdown)
  }

  return markdown
}

export const fetchPageMarkdownBySlug = async (
  slug: string,
): Promise<string | null> => {
  const page = await fetchPageBySlug(slug)
  if (!page) return null
  return fetchPageMarkdownByPageId(page.id)
}

export { normalizePageSlug }
export type { FlattenedBlogResponse }
