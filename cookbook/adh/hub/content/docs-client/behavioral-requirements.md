
- **doc-type-aliases**: `Doc`, `DocSummary`, and `DocFilters` MUST be
  structural aliases of `ResearchDocument` (`MarkdownDocumentRow`:
  `id`, `title`, `content`, `category?`, `tags: string[]`,
  `visibility: "private" | "public"`, `publicRoute?`), `ResearchSummary`
  (`MarkdownDocumentSummaryRow`: the same fields minus `content`, plus an
  optional `excerpt`), and `ResearchFilters` (`q?`, `category?`, `tag?`)
  respectively — `docsApi` MUST NOT define its own document, summary, or
  filter shape.
- **taxonomy-type-aliases**: `DocCategory` and `DocTag` MUST be structural
  aliases of `MarkdownCategoryNode` (`id`, `name`, `parentIds: string[]`,
  `sortOrder`) and `MarkdownKeywordNode` (`id`, `label`) respectively.
- **doc-marker-on-create**: `docsApi.create` MUST call `markdownApi.create`
  with `doc: true` merged into the caller's `body`, unconditionally, so
  every document `docsApi.create` mints is filed in the docs bucket.
- **create-body-retains-note-field**: `CreateDocBody` MUST be
  `Omit<CreateMarkdownBody, "doc">`, which removes only `doc` and leaves the
  optional `note` field from `CreateMarkdownBody` present on its type.
- **create-may-double-file**: A caller MAY set `note: true` on the body
  passed to `docsApi.create`; because `create-body-retains-note-field`
  leaves that field on the type and `doc-marker-on-create` always adds
  `doc: true`, the resulting `markdownApi.create` call MAY carry both
  markers, filing the new document in the notes bucket in addition to the
  docs bucket.
- **list-scoped-to-doc-marker**: `docsApi.list` MUST call `markdownApi.list`
  with `doc: true` merged into (and after) the caller's `opts`, so the
  returned `DocSummary[]` is restricted to documents carrying the docs
  marker.
- **id-ops-not-scoped-to-marker**: `docsApi.get`, `docsApi.update`, and
  `docsApi.remove` MUST forward their `id` and `opts` to the matching
  `markdownApi` operation with no `doc` field attached, and MUST therefore
  be able to read, edit, or delete any markdown document by id, whether or
  not it carries the docs marker — the marker filters what `list` returns,
  not what `get`/`update`/`remove` may address.
- **update-fields-only**: `docsApi.update`'s body type, `UpdateDocBody`, MUST
  be `UpdateMarkdownBody` unmodified (`content?`, `category?`, `tags?`); it
  MUST NOT carry a `doc`/`note` field, so an update call MUST NOT alter
  which bucket marker(s) a document has.
- **remove-is-void**: `docsApi.remove` MUST resolve to `void` and MUST NOT
  attempt to parse a response body, because `markdownApi.remove` issues the
  DELETE with `authedRequest` (not `authedJson`) against a 204 No Content
  response.
- **workspace-scopes-list-and-crud-ops**: `docsApi.list`, `get`, `create`,
  `update`, `remove`, `categories`, `createCategory`, `tags`, and `tagSet`
  MUST accept an optional `opts.workspace` and, when given, MUST forward it
  unchanged to the underlying `markdownApi` call, pinning the operation to
  that workspace's owning principal rather than the caller's own.
- **taxonomy-ops-not-workspace-scoped**: The re-exported `taxonomyApi`
  (`renameCategory`, `categoryParents`, `addCategoryParent`,
  `removeCategoryParent`, `deleteCategory`, `renameTag`, `deleteTag`) MUST
  NOT accept or send a `workspace` parameter on any of its seven operations,
  because the categories/category-edges/keywords tables they address are
  scoped by `customer_id`/`ecosystem_id` ownership, not by an
  `owner_kind`/`owner_id` column a workspace slug could narrow.
- **categories-share-vocabulary**: `docsApi.categories`, `createCategory`,
  `tags`, and `tagSet` MUST read and write the same category and tag rows a
  workspace's notes and other research documents use; there is no
  docs-only taxonomy.
- **category-tree-degrades-flat**: `docsApi.categories` MUST return
  whatever `categoryNodes()` computes: the backend's `nodes` array when the
  response carries one (even when it is empty), otherwise the backend's
  flat `items` name list rebuilt as root-level nodes
  (`id` and `name` both set to the name, `parentIds: []`, `sortOrder` set to
  the array index) in the order the backend sent them.
- **tag-set-degrades-flat**: `docsApi.tagSet` MUST return whatever
  `tagNodes()` computes: the backend's `nodes` array when present (even
  empty), otherwise the backend's flat `items` label list rebuilt with each
  row's `id` set to its own label.
- **create-category-conflict-message**: `docsApi.createCategory` MUST
  propagate `markdownApi.createCategory`'s mapping of a backend 409 to
  `Error('A category named "<name>" already exists somewhere else.')`
  (with `<name>` the requested category's `name`); every other rejection
  from that call MUST propagate unchanged.
- **errors-propagate-unmodified**: Except for `create-category-conflict-message`,
  every `docsApi` operation MUST propagate the exact error `authedJson` or
  `authedRequest` throws — network failure, a non-2xx status, or a
  JSON-parse failure — to its caller unmodified; neither `docsApi` nor
  `markdownApi`'s `list`/`get`/`create`/`update`/`remove` contains a
  `try`/`catch` of its own.
- **tags-array-guaranteed**: Every `Doc`/`DocSummary` returned by
  `docsApi.get`, `create`, `update`, or the rows in `list`'s result MUST
  have a `tags` array — never `undefined` or `null` — because
  `markdownApi` runs every such response through `withTags`, which defaults
  a missing or `null` tags field to `[]` while passing a real array through
  by reference, unchanged.
- **list-page-size-fixed**: `docsApi.list` MUST request `markdownApi`'s
  fixed page size of 200 rows on every call; it accepts no page-size or
  cursor parameter and performs no follow-up fetch, so a workspace with
  more than 200 documents matching the doc marker and filters MUST receive
  only the first 200, with no indication that more exist.
- **stateless-client**: `docsApi` MUST hold no local state, cache, or
  mutable field of its own; every operation issues exactly one HTTP
  request through `markdownApi`/`taxonomyApi` and its result depends only
  on that request's response.
- **create-not-idempotent**: `docsApi.create` MUST NOT deduplicate,
  coalesce, or queue concurrent or repeated calls with identical bodies —
  each call MUST result in one independent POST and therefore one new
  document with its own id.
- **no-client-side-retry**: `docsApi` MUST NOT retry a failed request; a
  rejected `authedJson`/`authedRequest` promise MUST reject the
  corresponding `docsApi` call exactly once, with no backoff or automatic
  replay attempted by this component.

