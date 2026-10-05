
This package (`packages/web/packages/data/src/markdown/`, re-exported whole by
`index.ts`) is a stateless, non-visual data-access layer with no store, no
cache, and no subscription mechanism — every call issues one request and
resolves or rejects with its result. It bundles three cooperating but
historically distinct clients:

- **`markdownApi`** (`markdown.ts`) is the sole client for a user's markdown
  research papers: list/search, full CRUD, publish/unpublish under a public
  route, and reads of the shared category/tag taxonomy. `docsApi` and the
  notes client are thin corpus-marker lenses over this same client (see
  `hub-domain-docs`); this recipe describes the client they both sit on.
- **`schemasApi`** (`schemas.ts`) is a CRUD client for storage-bucket schema
  definitions and their tables, addressed at `/api/bucket/buckets` and
  `/api/bucket/bucket-types`. Its own header comment states it plainly: this
  is "the EXISTING (pre-FTD) data layer, mechanically repointed to the
  renamed routes/columns so the hub keeps compiling after the buckets DB
  redesign" — it shares this folder with the markdown clients for historical
  reasons, not a domain relationship. The Apple Hub's `BucketsDataSource`
  (see `hub-domain-buckets`) is a separate implementation over the identical
  backend rows, under different model names (`Bucket`/`BucketTable` there,
  `SchemaDefinition`/`SchemaTable` here).
- **`taxonomyApi`** (`taxonomy.ts`) writes to the category/tag taxonomy that
  `markdownApi.categoryTree()`/`.tagSet()` read: rename, file/unfile under a
  parent, and delete (tombstone). It addresses a different backend door
  (the generic CRUD endpoints for categories, category-edges, and keywords)
  than the markdown-specific routes, by the taxonomy.ts header comment's own
  account of why: those operations already address a row by id, and
  re-publishing them on the markdown surface would just be a second
  representation of the generic layer's behavior.
- **`wire.ts`** is a type-only file: the backend row and request-body shapes
  both the Markdown and Buckets surfaces read and send, narrowed from the
  generated OpenAPI schema so this generic client never imports
  product-specific types.

