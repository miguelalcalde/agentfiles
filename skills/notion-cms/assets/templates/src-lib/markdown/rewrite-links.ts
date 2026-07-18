import { Client } from "@notionhq/client"

import { BLOG_PROPS_TO_IDS } from "../../../../notion-sdk/dbs/blog/constants"
import { normalizePageId, normalizePageSlug } from "../identity"

export type ResolvedLink = { href: string; title: string }

type ResolveLink = (pageId: string) => Promise<ResolvedLink | null>

const ROUTE_PREFIX = "/writings" // adapt per project

const MARKDOWN_LINK_RE = /\[([^\]]*)\]\(([^)]+)\)/g
const PAGE_TAG_RE =
  /<(?:page|mention-page)\s+url="([^"]+)"[^>]*>([^<]*)<\/(?:page|mention-page)>/g

const isNotionHost = (host: string): boolean => {
  const h = host.toLowerCase()
  return (
    h === "notion.so" ||
    h === "www.notion.so" ||
    h.endsWith(".notion.so") ||
    h.endsWith(".notion.site")
  )
}

const extractPageId = (urlString: string): string | null => {
  try {
    const url = new URL(urlString)
    const segments = decodeURIComponent(url.pathname).split("/").filter(Boolean)
    const last = segments[segments.length - 1] ?? ""
    const hyphenated = last.match(
      /([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})$/i,
    )
    if (hyphenated?.[1]) return hyphenated[1]
    const hex32 = last.match(/([a-f0-9]{32})$/i)
    if (hex32?.[1]) return hex32[1]
    const param = url.searchParams.get("p")
    if (param) return param
    return null
  } catch {
    return null
  }
}

const textFromProperty = (
  properties: Record<string, unknown>,
  varName: string,
  propId: string,
): string | null => {
  const direct = properties[varName]
  if (direct && typeof direct === "object" && "type" in direct) {
    const prop = direct as { type: string; title?: unknown[]; rich_text?: unknown[]; formula?: { type: string; string?: string } }
    if (prop.type === "title" && Array.isArray(prop.title)) {
      return prop.title.map((t) => (t as { plain_text?: string }).plain_text ?? "").join("")
    }
    if (prop.type === "rich_text" && Array.isArray(prop.rich_text)) {
      return prop.rich_text.map((t) => (t as { plain_text?: string }).plain_text ?? "").join("")
    }
    if (prop.type === "formula" && prop.formula?.type === "string") {
      return prop.formula.string ?? null
    }
  }
  for (const value of Object.values(properties)) {
    if (
      value &&
      typeof value === "object" &&
      "id" in value &&
      (value as { id: string }).id === propId
    ) {
      return textFromProperty({ tmp: value }, "tmp", propId)
    }
  }
  return null
}

const resolveFromNotion = async (
  notion: Client,
  pageId: string,
): Promise<ResolvedLink | null> => {
  try {
    const page = await notion.pages.retrieve({ page_id: pageId })
    if (!("properties" in page)) return null
    const props = page.properties as Record<string, unknown>
    const slug = normalizePageSlug(
      textFromProperty(props, "slug", BLOG_PROPS_TO_IDS.slug),
    )
    const title =
      textFromProperty(props, "name", BLOG_PROPS_TO_IDS.name)?.trim() ||
      textFromProperty(props, "title", BLOG_PROPS_TO_IDS.title)?.trim() ||
      "Untitled"
    return { href: `${ROUTE_PREFIX}/${slug || page.id}`, title }
  } catch {
    return null
  }
}

export const rewriteNotionLinks = async (
  markdown: string,
  notion: Client,
  resolvePublished: ResolveLink,
): Promise<string> => {
  const ids = new Set<string>()

  for (const match of markdown.matchAll(MARKDOWN_LINK_RE)) {
    try {
      const url = new URL(match[2].trim())
      if (isNotionHost(url.hostname)) {
        const id = extractPageId(match[2])
        if (id) ids.add(id)
      }
    } catch {
      /* skip */
    }
  }

  for (const match of markdown.matchAll(PAGE_TAG_RE)) {
    const id = extractPageId(match[1])
    if (id) ids.add(id)
  }

  const resolved = new Map<string, ResolvedLink | null>()
  await Promise.all(
    [...ids].map(async (id) => {
      const link =
        (await resolveFromNotion(notion, id)) ?? (await resolvePublished(id))
      resolved.set(normalizePageId(id), link)
    }),
  )

  let output = markdown.replace(MARKDOWN_LINK_RE, (full, text, href) => {
    try {
      const url = new URL(href.trim())
      if (!isNotionHost(url.hostname)) return full
      const id = extractPageId(href)
      if (!id) return full
      const link = resolved.get(normalizePageId(id))
      if (!link) return full
      return `[${text || link.title}](${link.href})`
    } catch {
      return full
    }
  })

  output = output.replace(PAGE_TAG_RE, (full, url, title) => {
    const id = extractPageId(url)
    if (!id) return full
    const link = resolved.get(normalizePageId(id))
    if (!link) return full
    return `[${title.trim() || link.title}](${link.href})`
  })

  return output
}
