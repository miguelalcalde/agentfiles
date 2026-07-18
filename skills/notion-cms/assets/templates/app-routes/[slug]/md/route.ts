import { fetchPageBySlug, fetchPageMarkdownByPageId } from "../data"

export const revalidate = 86400

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ slug: string }> },
) {
  const { slug } = await params
  const page = await fetchPageBySlug(slug)

  if (!page) {
    return new Response("Not found", { status: 404 })
  }

  const markdown = await fetchPageMarkdownByPageId(page.id)

  return new Response(markdown, {
    headers: { "content-type": "text/markdown; charset=utf-8" },
  })
}
