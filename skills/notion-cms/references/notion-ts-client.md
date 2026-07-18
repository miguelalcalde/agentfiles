# notion-ts-client

CLI: `npx notion-ts-client@latest`

Generates a typed TypeScript SDK from Notion databases connected to your
integration.

## Commands

```bash
# First time — creates config from connected databases
npx notion-ts-client@latest init --secret "$NOTION_TOKEN"

# Regenerate SDK after Notion schema changes
npx notion-ts-client@latest generate --sdk ./notion-sdk
```

With env vars set, `generate` needs no flags:

```bash
NOTION_TS_CLIENT_NOTION_SECRET=secret_...
NOTION_TS_CLIENT_CONFIG_PATH=./notion-sdk.json
NOTION_TS_CLIENT_SDK_PATH=./notion-sdk
npx notion-ts-client@latest generate
```

## Config file shape (`notion-sdk.json`)

```json
{
  "databases": {
    "uuid-with-dashes": {
      "_name": "Blog",
      "varName": "blog",
      "pathName": "blog",
      "properties": {
        "propertyId": {
          "_name": "isPublished",
          "_type": "checkbox",
          "varName": "isPublished",
          "readOnly": false
        }
      }
    }
  }
}
```

Editable fields:

- `varName` — camelCase name used in generated types and constants
- `readOnly` — when true, property omitted from PatchDTO (write safety)

Do not edit `_name`, `_type`, or property id keys — `generate` syncs these from
Notion.

## Generated output per database

```text
notion-sdk/dbs/<pathName>/
  constants.ts    PROPS_TO_IDS, IDS_TO_PROPS, PROPS_TO_TYPES, PROP_VALUES
  types.ts        *Response, *Query, *QueryFilter
  db.ts           *Database extends GenericDatabaseClass
  response.dto.ts *ResponseDTO with property getters
  patch.dto.ts    *PatchDTO for writes
  index.ts        re-exports
```

## Runtime imports (read path)

```typescript
import { BLOG_PROPS_TO_IDS } from "../../../notion-sdk/dbs/blog/constants"
import type { BlogResponse } from "../../../notion-sdk/dbs/blog/types"
```

Use `BLOG_PROPS_TO_IDS.isPublished` in query filters — Notion API expects
property **ids**, not display names.

## Optional: generated Database class (write path)

```typescript
import { BlogDatabase } from "../../../notion-sdk/dbs/blog/db"
import { BlogPatchDTO } from "../../../notion-sdk/dbs/blog/patch.dto"

const db = new BlogDatabase({ notionSecret: process.env.NOTION_TOKEN! })
const result = await db.query({
  filter: { isPublished: { equals: true } },
  sorts: [{ property: "publishedAt", direction: "descending" }],
})
```

## Production caveats (from upstream docs)

- **Property renamed in Notion:** queries still work (property ids). `getPage`
  mapping by name can break until regenerate.
- **Property removed or type changed:** regenerate SDK, fix TS errors before
  deploying schema change to production.
- **New database added to integration:** `generate` prompts to add or ignore.

## knip / lint

Add `notion-sdk/**` to dead-code tool ignore lists — generated files reference
many symbols only used at type level.
