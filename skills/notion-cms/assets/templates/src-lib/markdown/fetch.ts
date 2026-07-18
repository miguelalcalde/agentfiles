import { Client } from "@notionhq/client"

import { getNotionToken } from "../config"

export const fetchPageMarkdown = async (pageId: string): Promise<string> => {
  const notion = new Client({
    auth: getNotionToken(),
    notionVersion: "2026-03-11",
  })

  const response = await notion.pages.retrieveMarkdown({
    page_id: pageId,
  })

  if (response.truncated && response.unknown_block_ids.length > 0) {
    const extras = await Promise.all(
      response.unknown_block_ids.map(async (blockId) => {
        const subtree = await notion.pages.retrieveMarkdown({
          page_id: blockId,
        })
        return subtree.markdown
      }),
    )
    return [response.markdown, ...extras].join("\n\n")
  }

  return response.markdown
}
