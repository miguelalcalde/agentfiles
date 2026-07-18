import {
  fetchPublishedBlogPosts,
  normalizePageSlug,
} from "./[slug]/data"

export const revalidate = 300

export default async function IndexPage() {
  const posts = await fetchPublishedBlogPosts(100)

  return (
    <main>
      <h1>Writings</h1>
      <ul>
        {posts.map((post) => (
          <li key={post.id}>
            <a href={`/writings/${normalizePageSlug(post.slug) || post.id}`}>
              {post.name}
            </a>
            {post.summary ? <p>{post.summary}</p> : null}
          </li>
        ))}
      </ul>
    </main>
  )
}
