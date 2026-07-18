import type { FlattenedBlogResponse } from "./notion-flatten"

export const normalizePageSlug = (slug: string | null | undefined): string =>
  slug?.trim().toLowerCase() ?? ""

export const normalizePageId = (value: string): string =>
  value.replaceAll("-", "").toLowerCase()

export const matchesSlug = (
  page: FlattenedBlogResponse,
  requestedSlug: string,
): boolean => {
  const normalizedSlug = normalizePageSlug(requestedSlug)
  const normalizedRequestedId = normalizePageId(requestedSlug)
  const normalizedPageSlug = normalizePageSlug(page.slug)
  const normalizedPageId = normalizePageId(page.id)

  return (
    normalizedPageSlug === normalizedSlug ||
    normalizedPageId === normalizedRequestedId
  )
}
