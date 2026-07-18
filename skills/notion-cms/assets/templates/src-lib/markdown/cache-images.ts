import { createHash } from "node:crypto"
import { mkdir, readFile, writeFile } from "node:fs/promises"
import path from "node:path"

const IMAGE_RE = /!\[([^\]]*)\]\((https?:\/\/[^)]+)\)/g
const NOTION_STATIC_HOST = "notion-static.com"
const CACHE_DIR = path.join(process.cwd(), "public", "notion-media")

const hashUrl = (url: string): string =>
  createHash("sha256").update(url).digest("hex").slice(0, 16)

const extensionFromUrl = (url: string): string => {
  try {
    const pathname = new URL(url).pathname
    const ext = path.extname(pathname).slice(1).toLowerCase()
    if (["png", "jpg", "jpeg", "gif", "webp", "svg"].includes(ext)) return ext
  } catch {
    /* fall through */
  }
  return "bin"
}

const cacheImageUrl = async (url: string): Promise<string> => {
  if (!url.includes(NOTION_STATIC_HOST)) return url

  await mkdir(CACHE_DIR, { recursive: true })
  const filename = `${hashUrl(url)}.${extensionFromUrl(url)}`
  const filePath = path.join(CACHE_DIR, filename)
  const publicPath = `/notion-media/${filename}`

  try {
    await readFile(filePath)
    return publicPath
  } catch {
    /* not cached yet */
  }

  const response = await fetch(url)
  if (!response.ok) return url

  const buffer = Buffer.from(await response.arrayBuffer())
  await writeFile(filePath, buffer)
  return publicPath
}

export const cacheNotionImagesInMarkdown = async (
  markdown: string,
): Promise<string> => {
  const replacements: Array<{ from: string; to: string }> = []

  for (const match of markdown.matchAll(IMAGE_RE)) {
    const alt = match[1]
    const url = match[2]
    if (!url.includes(NOTION_STATIC_HOST)) continue
    const cached = await cacheImageUrl(url)
    if (cached !== url) {
      replacements.push({
        from: `![${alt}](${url})`,
        to: `![${alt}](${cached})`,
      })
    }
  }

  let output = markdown
  for (const { from, to } of replacements) {
    output = output.replace(from, to)
  }
  return output
}
