# Enhanced markdown

Notion's markdown output extends GFM with XML-like tags. Reference:
https://developers.notion.com/guides/data-apis/enhanced-markdown

## Common constructs

### Page and database references

```html
<page url="https://www.notion.so/...">Child page title</page>
<database url="https://www.notion.so/..." inline="false">DB name</database>
```

Rewrite to internal routes during post-processing:

```markdown
[Child page title](/writings/child-slug)
```

### Mentions

```html
<mention-page url="https://www.notion.so/...">Page title</mention-page>
<mention-user url="...">User name</mention-user>
```

Handle `<mention-page>` like `<page>` for internal link rewriting. User mentions
can stay as-is or render with a custom MDX component.

### Callouts

```html
<callout icon="💡" color="yellow_bg">
Content here
</callout>
```

Options for MDX:

- Pass through as custom element + MDX component mapping
- Strip tags and render inner content as a blockquote
- Leave for a later polish pass

### Toggles

```html
<details>
<summary>Toggle title</summary>
Hidden content
</details>
```

Often compatible with remark-gfm or raw HTML in MDX.

### Standard elements

| Block | Markdown |
|---|---|
| Headings | `#` / `##` / `###` |
| Bulleted list | `- item` |
| Numbered list | `1. item` |
| To-do | `- [ ]` / `- [x]` |
| Quote | `> quote` |
| Divider | `---` |
| Code | Fenced with language |
| Math | `$$ ... $$` |
| Image | `![caption](url)` |
| Table | GFM table syntax |

## Link rewriting targets

Run rewrite pass on:

1. `[text](https://...notion.so/...)` — standard markdown links
2. `<page url="URL">Title</page>` — enhanced page refs
3. `<mention-page url="URL">Title</mention-page>` — inline mentions

Extract page id from URL path (32-char hex or hyphenated uuid). Resolve against
published CMS entries or `pages.retrieve` fallback.

## MDX compatibility

`next-mdx-remote` with `remark-gfm` handles most standard markdown. Unknown
XML-like tags may:

- Pass through if MDX allows raw HTML
- Fail compile — strip or map to components

For initial setup, prioritize link rewriting and standard blocks. Add callout/
toggle components when polishing.
