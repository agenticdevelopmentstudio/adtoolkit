
- **Decision**: `notesApi` is implemented as a thin marker lens over `markdownApi` rather than a dedicated `/content/notes` route set, even though that surface exists on the backend.
  **Rationale**: the module's own header comment states a parallel route set "would have had to re-derive the version-snapshot and classification invariants `markdownDocuments.ts` already owns, and would have drifted."
  **Approved**: pending
- **Decision**: the backend's separate `/content/notes` surface is documented but never called by this client.
  **Rationale**: per the module comment, it is "the device-SYNC marker surface — content only, no title/category/tags, no workspace — and it has no web consumer," so it is deliberately not what `notesApi` talks to.
  **Approved**: pending
- **Decision**: `CreateNoteBody` omits only `note` from `CreateMarkdownBody`, leaving `doc` available, so one `create` call can file a new document in both the notes and docs buckets.
  **Rationale**: per `markdown.ts`'s comment on `MarkdownCreateBody`, `note` and `doc` are independent markers "because the markers they mint are independent rows: nothing in the schema stops one text from sitting on both shelves" — `CreateNoteBody`'s `Omit` narrows only the one field this client's own contract cares about (that `note` is always `true`) and takes no position on `doc`.
  **Approved**: pending
- **Decision**: the re-exported `taxonomyApi` accepts no `workspace` parameter on any of its seven operations, unlike every other operation this component exposes.
  **Rationale**: per `taxonomy.ts`'s module comment, the categories/category-edges/keywords tables are scoped by `customer_id`/`ecosystem_id` ownership rather than an `owner_kind`/`owner_id` column, so the workspace pin "only applies to tables with owner_kind / owner_id columns, which these do not have" — adding the parameter would not narrow anything and would misstate the endpoint's real scoping.
  **Approved**: pending
- **Decision**: `notesApi.categories()` calls `markdownApi.categoryTree` and returns node rows, while `notesApi.tags()` calls `markdownApi.tags` and returns the plain flat label list — the two sibling lookups do not share one return shape, and only `tagSet()` gets the node-row treatment `categories()` gets by default.
  **Rationale**: `notes.ts`'s own doc comments name the intent directly: `categories()` is described as the notebook rail's hierarchy source, while `tags()` is "the workspace's tag labels (the tag field's autocomplete source)" with `tagSet()` separately documented as "the same tags WITH their ids" for the manager that renames/deletes them — the asymmetry is deliberate, not an oversight, and a port that gives both methods one shared shape would silently change which one degrades and which one is the raw autocomplete source.
  **Approved**: pending
- **Decision**: for an org workspace, `notesApi` leaves org-shared note semantics undefined beyond ordinary org-document ownership.
  **Rationale**: `notesApi`'s own comment states this plainly — "For an ORG workspace this is the whole of the ownership story today — org-SHARED note semantics are still undesigned, so an org note is simply an org-owned document, and the marker carries only its creator stamp" — recorded here as the current, deliberate scope rather than smoothed over.
  **Approved**: pending

