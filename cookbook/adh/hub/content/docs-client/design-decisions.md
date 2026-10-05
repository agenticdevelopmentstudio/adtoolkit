
- **Decision**: `docsApi.get`, `update`, and `remove` address a document
  purely by id, applying no `doc`-marker check, while `list` and `create`
  do apply the marker.
  **Rationale**: per `docs.ts`'s own module comment, the `content.docs`
  marker exists to file a document in "the owner's `docs` storage bucket"
  — it constrains which documents a listing or a new creation touches, not
  which documents a caller who already holds an id may read, edit, or
  delete.
  **Approved**: pending
- **Decision**: `CreateDocBody` omits only `doc` from `CreateMarkdownBody`,
  leaving `note` available, so one `create` call can file a new document
  in both the docs and notes buckets.
  **Rationale**: per `markdown.ts`'s comment on `MarkdownCreateBody`,
  `note` and `doc` are independent markers "because the markers they mint
  are independent rows: nothing in the schema stops one text from sitting
  on both shelves" — `CreateDocBody`'s `Omit` narrows only the one field
  this client's own contract cares about (that `doc` is always `true`) and
  takes no position on `note`.
  **Approved**: pending
- **Decision**: The re-exported `taxonomyApi` accepts no `workspace`
  parameter on any of its seven operations, unlike every other operation
  this component exposes.
  **Rationale**: per `taxonomy.ts`'s module comment, the categories/
  category-edges/keywords tables are scoped by `customer_id`/
  `ecosystem_id` ownership rather than an `owner_kind`/`owner_id` column,
  so "the workspace pin only applies to tables with owner_kind /
  owner_id columns, which these do not have" — adding the parameter would
  not narrow anything and would misstate the endpoint's real scoping.
  **Approved**: pending
- **Decision**: `docsApi.categories()` and `docsApi.tagSet()` degrade a
  pre-hierarchy backend's flat name/label list into synthetic root nodes
  (id equal to the name/label) instead of returning an empty tree or set.
  **Rationale**: per `markdown.ts`'s comments on `categoryNodes` and
  `tagNodes`, those flat lists are "the entire category set such a backend
  HAS," and every existing consumer filters or links a category or tag by
  name/label rather than by id, so rebuilding roots keeps a working (if
  flat) result instead of emptying it.
  **Approved**: pending
- **Decision**: `docsApi.list` always requests a fixed page of 200 rows
  with no cursor or page-size parameter exposed.
  **Rationale**: per `markdown.ts`'s comment on `PAGE_SIZE`, "a user's own
  research set is small, and the master list shows everything at once (no
  pagination UI)," and 200 is stated as the backend's own page cap —
  pagination was not built because no consumer needed it yet, not because
  the backend cannot support it.
  **Approved**: pending

