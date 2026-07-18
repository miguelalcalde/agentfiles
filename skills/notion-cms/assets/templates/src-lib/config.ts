export const NOTION_API_VERSION = "2026-03-11"

export const BLOG_DATABASE_ID =
  process.env.NOTION_BLOG_DATABASE_ID ?? "YOUR_DATABASE_ID"

export const getNotionToken = (): string => {
  const token = process.env.NOTION_TOKEN
  if (!token) {
    throw new Error("NOTION_TOKEN is required")
  }
  return token
}

export const isDebugEnabled = (): boolean => {
  const debug = process.env.DEBUG?.trim().toLowerCase()
  return Boolean(debug && debug !== "0" && debug !== "false")
}
