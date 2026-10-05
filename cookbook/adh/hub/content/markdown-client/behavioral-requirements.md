
### markdown.ts — research documents (list, CRUD, publish, taxonomy reads)

- **research-document-crud-shape**: `markdownApi` MUST expose exactly these
  thirteen operations: `list`, `get`, `create`, `update`, `remove`,
  `routeAvailable`, `publish`, `unpublish`, `categories`, `categoryTree`,
  `createCategory`, `tags`, `tagSet`.
- **workspace-scopes-every-op**: every markdown.ts operation that accepts an
  `opts.workspace` MUST append it to its request URL via `workspaceQuery`;
  the backend uses it to pin the op to that workspace's owning principal
  (list returns only documents that principal owns, create stamps it as
  owner, item ops resolve org-owned documents another member created), and
  an op called without it falls back to the caller's own documents.
- **list-page-size-fixed**: `markdownApi.list` MUST always request the fixed
  `PAGE_SIZE` of 200 rows (`pageSize=200` in the query string) and MUST NOT
  accept or send any cursor, offset, or page-number parameter from the
  caller.
- **list-query-omits-blank-filters**: `listQuery` MUST trim `filters.q`,
  `filters.category`, and `filters.tag` and MUST omit each from the query
  string entirely when the trimmed value is empty, rather than sending an
  empty-string parameter.
- **list-corpus-flags-are-independent**: `opts.noted` and `opts.doc` MUST
  each be sent only when truthy (`noted=true`/`doc=true`), and a `false` or
  absent value is not an instruction to exclude that corpus — per the
  source's own comment, the backend offers no such exclusion set, so a
  falsy flag simply leaves the list unfiltered by corpus.
- **tags-array-guaranteed**: `withTags` MUST return its input unchanged (the
  same object reference) when `tags` is already an array, and MUST
  otherwise return a shallow copy with `tags: []`; `markdownApi.list`,
  `.get`, `.create`, `.update`, `.publish`, and `.unpublish` MUST each run
  their result through `withTags` before resolving, so every document this
  client hands back has an array `tags` field regardless of backend
  version.
- **remove-is-a-204-no-content-call**: `markdownApi.remove` MUST issue its
  DELETE through `authedRequest`, not `authedJson`, and MUST resolve `void`
  with no attempt to parse a response body, matching the backend's 204 No
  Content response.
- **route-availability-excludes-self**: `markdownApi.routeAvailable` MUST GET
  `/api/content/markdown/{id}/route-available/{route}` with both `id` and
  `route` percent-encoded as path segments (each via `enc`) and MUST return
  the backend's `{available, reason}` verdict unchanged; per the source
  comment, the backend's own answer already excludes the document's own
  current route from counting as taken.
- **publish-conflict-mapping**: `markdownApi.publish` MUST POST `{route}` to
  `/api/content/markdown/{id}/publish` and, when the request throws a
  conflict (`isConflict`), MUST discard that error and throw a new `Error`
  whose message is exactly `The route "<route>" is already used by one of
  your papers.` (source uses curly quotes around `<route>`); every other
  thrown error MUST propagate unmodified.
- **create-category-idempotent-on-matching-parents**: re-posting an existing
  category name to `markdownApi.createCategory` is documented as idempotent
  when every `parentIds` entry the call asks for is already one of that
  category's parents, and a 409 otherwise, because a category name is
  unique per owner and this call never re-files an existing category.
- **create-category-conflict-mapping**: on a 409 from
  `POST /api/content/markdown/categories`, `markdownApi.createCategory` MUST
  discard the raw error and throw a new `Error` whose message is exactly `A
  category named "<name>" already exists somewhere else.` (source uses
  curly quotes around `<name>`); every other thrown error MUST propagate
  unmodified.
- **category-tree-degrades-flat**: `categoryNodes(res)` MUST return
  `res.nodes` unchanged (same array reference) whenever it is an array,
  including an empty one, and MUST otherwise rebuild `res.items` (or `[]`
  when that is not an array either) into `MarkdownCategoryNode` rows with
  `id` and `name` both set to the item's name string, `parentIds: []`, and
  `sortOrder` set to the item's index in the array.
- **tag-set-degrades-flat**: `tagNodes(res)` MUST follow the identical rule
  as `categoryNodes`, except a rebuilt row's `id` and `label` are both set
  to the item's label string.
- **errors-propagate-unmodified**: every markdown.ts operation other than
  `publish` and `createCategory` MUST let a thrown error from `authedJson`
  or `authedRequest` propagate to its caller unchanged; no other operation
  catches, wraps, logs, or discards an error.
- **create-body-has-no-title-field**: `CreateMarkdownBody`/`UpdateMarkdownBody`
  MUST NOT carry a `title` field; the backend derives a document's title
  from its content (frontmatter, else the first line) so that one document
  reads the same way in every client.

### schemas.ts — bucket/schema-definition CRUD (legacy pre-FTD Buckets data layer)

- **schemas-api-shape**: `schemasApi` MUST expose exactly five operations:
  `list`, `get`, `create`, `update`, `delete`.
- **schema-definition-derivation**: `toDefinition(bucketRow, allTableRows)`
  MUST build a `SchemaDefinition` whose `id`/`name`/`ecosystemId`/
  `createdAt`/`updatedAt` come from the bucket row, whose `description`
  comes from `bucketRow.metadata.description` (empty string when metadata
  or that field is absent), whose `kind` is `bucketRow.kind ?? "custom"`,
  and whose `tables` is every `BucketTypeRow` whose `bucketId` matches the
  bucket's `id`, mapped to `{id, name, type: sqlTableName}`.
- **list-composes-two-endpoints-unfiltered**: `schemasApi.list` MUST fetch
  the full contents of `/api/bucket/buckets` and `/api/bucket/bucket-types`
  in parallel (`Promise.all`, no server-side filter on either), scope the
  bucket rows to the given `ecosystemId` client-side via `scopeByOwner` when
  one is passed, map each into a `SchemaDefinition`, and return the result
  sorted alphabetically by name via `sortByText` (locale-aware
  `localeCompare`, non-mutating).
- **schema-table-name-precondition-undeclared**: `SchemaTable.name`'s doc
  comment documents a caller precondition ("no spaces") that no code in
  schemas.ts enforces; the only validation this file actually performs on
  table names is `assertUniqueTableNames`'s case-insensitive-trimmed
  duplicate check, so a name containing spaces is accepted and sent to the
  backend as-is.
- **create-rejects-duplicate-table-names-first**: `schemasApi.create` MUST
  call `assertUniqueTableNames(input.tables)` before issuing any network
  request, and that function MUST throw synchronously on the first
  case-insensitive, trimmed duplicate name it finds within the given array,
  with message `Duplicate table name "<name>" in this bucket.` (using the
  trimmed, original-case name).
- **create-conflict-mapping**: on a 409 from the initial
  `POST /api/bucket/buckets`, `schemasApi.create` MUST rethrow via
  `rethrowConflict` with message `A bucket named "<name>" already exists.`;
  every other thrown error at that step MUST propagate unmodified.
- **create-sequential-children-with-rollback**: after the parent bucket is
  created, `schemasApi.create` MUST POST each of `input.tables` to
  `/api/bucket/bucket-types` sequentially (one at a time, not in parallel);
  if any of those POSTs throws, it MUST call `rollbackSchema` — which
  deletes every table row created so far and the parent bucket row via
  `Promise.allSettled`, deliberately swallowing any error from the cleanup
  calls themselves — and MUST then rethrow the original table-creation
  error unchanged, per the source's own stated goal of avoiding "orphaning
  a half-built schema."
- **update-is-a-partial-patch**: `schemasApi.update` MUST build its bucket
  PUT body via `compact({name, metadata})`, sending only the fields that
  were actually given (compact drops `undefined` keys, preserves `null`);
  when the resulting patch is empty, it MUST issue a GET of the bucket
  instead of a PUT.
- **update-table-reconcile-ordering**: when `input.tables` is given,
  `schemasApi.update` MUST first delete (sequentially, each awaited) every
  currently-fetched table whose id is absent from the desired set, and only
  after all of those deletions complete MUST it add or patch the desired
  tables; the source's own comment states this ordering exists because
  running both directions in one batch would race the backend's unique
  `(schema, name)` index.
- **update-table-add-vs-patch**: for each table in `input.tables`,
  `schemasApi.update` MUST POST a new bucket-type when the table's id is
  not among the currently-fetched table ids, and MUST PUT (patching only
  `name` and `sqlTableName`) when the id is present and either field
  differs from the currently-fetched row; a table whose id is present and
  whose `name`/`type` both already match MUST trigger no request at all.
- **update-refetches-final-tables**: `schemasApi.update` MUST re-fetch the
  bucket's tables after all table mutations complete, and MUST build the
  returned `SchemaDefinition` from that re-fetched set, because a newly
  added table's id is minted by the backend and unknown until the insert
  response (or a re-fetch) returns it.
- **delete-removes-children-then-parent**: `schemasApi.delete` MUST fetch
  and delete every table belonging to the bucket (in parallel) before
  deleting the parent bucket row, per the source's own stated reason: "No
  DB-level cascade from buckets to bucket_types."
- **schemas-get-swallows-errors**: the schema lookup-by-id operation `schemasApi.get` wraps its entire body in a bare catch that returns `null` with no binding on the caught value, so a genuine 404, a 500, a 403, and a network failure are all indistinguishable from "no such schema" to every caller; the source does not state which of those cases the `null` return is meant to represent.
- **schemas-update-reconcile-has-no-rollback-or-lock**: unlike `create`, which calls `rollbackSchema` to avoid an orphaned half-built schema, `schemasApi.update`'s table-reconcile loop (delete-then-add/patch) has no compensating action if a DELETE, POST, or PUT partway through the sequence throws, and no lock or version check against a second concurrent `update` on the same schema id reading the same "current tables" snapshot; either case can leave a schema's persisted table set inconsistent with what any caller asked for, with no defined recovery path.

### taxonomy.ts — category/tag taxonomy writes (generic CRUD door)

- **taxonomy-ops-not-workspace-scoped**: `taxonomyApi`'s seven
  operations MUST NOT accept or send a `workspace` query parameter; per the
  module's own header comment, these tables are scoped by `customer_id` +
  `ecosystem_id` as an ownership stamp rather than by an `owner_kind`/
  `owner_id` column the workspace pin could filter on, so a platform
  principal already addresses any row in their own ecosystem without one.
- **rename-by-id-not-by-name**: `renameCategory` and `renameTag` MUST PUT
  `{name}`/`{label}` to `/api/content/categories/{id}` and
  `/api/content/keywords/{id}` respectively, addressing the row by id so
  that every document or edge already pointing at that id is renamed with
  it, with no separate propagation step.
- **category-parents-fetched-fresh-at-write-time**: `categoryParents(childId)`
  MUST GET `/api/content/category-edges?childId={id}` and return the raw
  edge array; `removeCategoryParent` MUST call it at the moment it writes
  (not accept a caller-supplied snapshot), per the source's own comment,
  because a `MarkdownCategoryNode` carries parent ids but not edge ids, and
  acting on the current links rather than whatever the screen last rendered
  from is a deliberate freshness guarantee.
- **add-category-parent-cycle-and-self-link-rejection**: `addCategoryParent`
  MUST POST `{childId, parentId}` to `/api/content/category-edges`; the
  backend is documented to refuse a link that would close a cycle with a
  409 and a self-link with a 400, and the source's own comment states a
  caller MUST handle both even after filtering its own menu, because "the
  graph it filtered against is a snapshot" that another caller may have
  changed since.
- **remove-category-parent-is-idempotent**: `removeCategoryParent` MUST
  fetch the child's current parent edges, then sequentially DELETE
  (awaiting each) only the edges whose `parentId` matches the given
  `parentId`; when no such edge exists it MUST issue zero DELETE calls and
  resolve without error, so a duplicate call or a retry costs the same as
  one call.
- **delete-category-cascades-server-side**: `deleteCategory` MUST issue
  exactly one DELETE to `/api/content/categories/{id}` and rely on the
  backend's own transaction for the category's cascade: a document under
  the deleted category becomes uncategorized rather than hidden, and a
  child category is transitively retired only when it has no other live
  parent; per the source's comment, because the cascade lives entirely in
  the backend, every caller of this endpoint observes the same rule and a
  concurrent re-filing of the same subtree cannot race a caller's own walk
  of it.
- **delete-tag-tombstone-is-revivable**: `deleteTag` MUST issue exactly one
  DELETE to `/api/content/keywords/{id}`; per the source's comment, because
  a label is unique per owner, later renaming or creating a category with
  that exact label revives the tombstoned row (and its old links) rather
  than minting a new one — the one way a tag's delete differs from a
  category's.

### wire.ts — wire shapes and their invariants

- **category-node-is-a-dag**: `MarkdownCategoryNode.parentIds` MUST be an
  array (`[]` for no parents, never a null sentinel), allowing a category to
  sit under any number of parents at once; the backend is documented to
  filter out parent ids not themselves present in `nodes` and to refuse an
  edge that would close a cycle, so a consumer folding this into a tree is
  guaranteed to terminate.
- **update-body-supports-explicit-null-category**: `MarkdownUpdateBody.category`
  MUST accept `string | null | undefined`, where `null` explicitly clears
  the document's category and `undefined` (an omitted field) leaves it
  unchanged — these are two distinct instructions, not one.
- **route-availability-reason-enum**: `MarkdownRouteAvailability.reason` MUST
  be one of exactly `"ok"`, `"invalid"`, `"reserved"`, or `"taken"`, letting
  a caller distinguish a malformed slug from a site-reserved word from one
  already claimed by another of the author's documents.
- **bucket-metadata-is-narrowed-jsonb**: `BucketRow.metadata` MUST be typed
  as `{description?: string} | null`, a client-side narrowing of the
  backend's untyped jsonb column to exactly the one field this package
  reads (`description`); any other key the backend may store there is
  invisible to this client.

