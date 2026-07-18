import { BLOG_IDS_TO_PROPS } from "../../../notion-sdk/dbs/blog/constants"
import type { BlogResponse } from "../../../notion-sdk/dbs/blog/types"

type NotionPropertyLike = {
  id: string
  type: string
} & Record<string, unknown>

export type FlatNotionPropertyValue =
  | string
  | number
  | boolean
  | Date
  | null
  | string[]

const toPlainText = (value: unknown): string => {
  if (!Array.isArray(value)) return ""
  return value
    .map((item) => {
      if (!item || typeof item !== "object") return ""
      const text = (item as { plain_text?: unknown }).plain_text
      return typeof text === "string" ? text : ""
    })
    .join("")
}

const toSimpleValue = (property: NotionPropertyLike): FlatNotionPropertyValue => {
  switch (property.type) {
    case "title":
      return toPlainText(property.title)
    case "rich_text":
      return toPlainText(property.rich_text)
    case "number":
      return typeof property.number === "number" ? property.number : null
    case "checkbox":
      return Boolean(property.checkbox)
    case "select": {
      const select = property.select as { name?: string } | null
      return select?.name ?? null
    }
    case "multi_select":
      return Array.isArray(property.multi_select)
        ? property.multi_select
            .map((item) => (item as { name?: string }).name)
            .filter((name): name is string => Boolean(name))
        : []
    case "date": {
      const start = (property.date as { start?: string } | null)?.start
      return start ? new Date(start) : null
    }
    case "created_time":
      return property.created_time ? new Date(String(property.created_time)) : null
    case "last_edited_time":
      return property.last_edited_time
        ? new Date(String(property.last_edited_time))
        : null
    case "formula": {
      const formula = property.formula as Record<string, unknown>
      if (formula.type === "string") return String(formula.string ?? "")
      if (formula.type === "number") return Number(formula.number)
      if (formula.type === "boolean") return Boolean(formula.boolean)
      return null
    }
    default:
      return null
  }
}

type BlogPropertyName = (typeof BLOG_IDS_TO_PROPS)[keyof typeof BLOG_IDS_TO_PROPS]

export type FlattenedBlogResponse = BlogResponse & {
  name: string
  slug: string | null
  isPublished: boolean
  publishedAt: Date | null
  summary: string
  description: string
  tags: string[]
}

export const flattenBlogResponse = (response: BlogResponse): FlattenedBlogResponse => {
  const flat = Object.values(response.properties).reduce<
    Partial<Record<BlogPropertyName, FlatNotionPropertyValue>>
  >((acc, property) => {
    const name = BLOG_IDS_TO_PROPS[property.id as keyof typeof BLOG_IDS_TO_PROPS]
    if (name) acc[name] = toSimpleValue(property as NotionPropertyLike)
    return acc
  }, {})

  return {
    ...response,
    name: typeof flat.name === "string" ? flat.name : "",
    slug: typeof flat.slug === "string" ? flat.slug : null,
    isPublished: flat.isPublished === true,
    publishedAt: flat.publishedAt instanceof Date ? flat.publishedAt : null,
    summary: typeof flat.summary === "string" ? flat.summary : "",
    description: typeof flat.description === "string" ? flat.description : "",
    tags: Array.isArray(flat.tags) ? flat.tags : [],
  }
}
