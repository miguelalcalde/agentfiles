import { notFound } from "next/navigation"

import { renderMdx } from "@/lib/mdx"

import {
  fetchPageBySlug,
  fetchPageMarkdownByPageId,
  fetchPublishedBlogPosts,
  normalizePageSlug,
} from "./data"

export const revalidate = 86400

export default async function DetailPage({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  const page = await fetchPageBySlug(slug)

  if (!page) {
    notFound()
  }

  const markdown = await fetchPageMarkdownByPageId(page.id)
  const content = await renderMdx(markdown)

  return (
    <main>
      <h1>{page.name}</h1>
      {!page.isPublished ? <span>Draft</span> : null}
      {page.publishedAt ? (
        <p>Published {page.publishedAt.toLocaleDateString()}</p>
      ) : null}
      <article>{content}</article>
    </main>
  )
}

export async function generateStaticParams() {
  const posts = await fetchPublishedBlogPosts(20)
  return posts.map((post) => ({
    slug: normalizePageSlug(post.slug) || post.id,
  }))
}
