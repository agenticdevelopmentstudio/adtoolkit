
`docsApi` (`packages/web/packages/data/src/docs/docs.ts`, re-exported by
`docs/index.ts`) is a **logic** component — no visual surface. It is the
third lens on the shared markdown-document surface, alongside `notesApi` and
the plain research-paper use of `markdownApi` itself. A doc IS a markdown
document — same row shape, same category/tag taxonomy, same CRUD routes
(`/content/markdown`) — and what makes a document a doc is a `content.docs`
storage-bucket MARKER, minted by sending `doc: true` on create and read back
by filtering `list` with the same flag. `docsApi` exists only to bake that
marker in so a caller cannot forget it; every operation it exposes forwards
directly to `markdownApi` (list/get/create/update/remove/categoryTree/
createCategory/tags/tagSet) or re-exports `taxonomyApi` unchanged for
renaming, filing, unfiling and retiring the categories and tags that
`docsApi.categories`/`docsApi.tagSet` read. `docsApi` itself contains no
HTTP call, no wire-shape knowledge, and no taxonomy logic of its own.

