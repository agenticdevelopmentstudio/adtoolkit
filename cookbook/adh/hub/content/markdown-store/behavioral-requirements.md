
### Schema & Migration

- **table-set**: The schema MUST define exactly the named tables (`markdown`,
  `notes`, `docs`, `papers`, `categories`, `category_edges`, `category_items`,
  `keywords`, `keyword_items`), and the projection's resource list MUST derive from
  that same table list rather than a hand-copied one, so the sync engine's resource
  set cannot drift from the schema.
- **marker-table-shape**: `notes`, `docs`, and `papers` MUST share one generated
  shape: a `UNIQUE(ecosystem_id, id)` constraint plus a partial unique index scoped
  to `markdown_id` where `deleted_at IS NULL`, so a document may hold at most one
  live marker row of each kind.
- **document-column-checks**: The `markdown` table MUST enforce `visibility IN
  ('private','public')`, `stage IN ('draft','final')`, `owner_kind IN
  ('customer','organization')`, and `is_deleted IN (0,1)` as CHECK constraints, so an
  invalid enum value is a write-time SQL failure rather than a value the reader must
  tolerate.
- **author-route-uniqueness**: The `markdown` table MUST enforce a partial unique
  index over customer and `public_route` scoped to non-null, non-deleted rows, so two
  live documents from the same customer can never publish the same route.
- **adh-source-uniqueness**: The `markdown` table MUST enforce a partial unique
  expression index on the `adh_source` key extracted from `frontmatter`, so a
  document already linked to one adh id cannot be duplicated under a second local
  row.
- **self-edge-refusal**: `category_edges` MUST enforce a CHECK constraint refusing
  `parent_id` to equal `child_id`, so a category cannot become its own parent
  independent of any application-level cycle check.
- **keyword-label-uniqueness**: `keywords` MUST enforce a unique constraint over
  customer, ecosystem, and label together, so a label is unique per author within one
  ecosystem.
- **migration-sequence**: The schema's migrator MUST apply its five migrations,
  `markdown-v1` through `markdown-v5-outbox-claim`, in order, and the migration step
  MUST turn on foreign-key enforcement before migrating, so enforcement is active
  before any migrated row is written.
- **frontmatter-owner-backfill**: The `markdown-v3-frontmatter-owner` migration MUST
  claim the `pinned` frontmatter key for every document that already carries it on
  disk, so a database upgraded from an earlier version does not silently show
  `pinned` as unowned.
- **title-claim-release**: The `markdown-v4-release-title-claims` migration MUST
  delete every stale `title` claim, leaving an upgraded database with no `title`
  claim outstanding.
- **outbox-shape-frozen**: The `_markdown_outbox` table's original shape MUST stay
  frozen; ordering was added by a separate `seq` column in
  `markdown-v2-outbox-order` and in-flight tracking by a separate `claimed_at` column
  in `markdown-v5-outbox-claim`, rather than by altering the original columns.

### Timestamp Normalization

- **single-formatter-pair**: Every column-to-date conversion in this component MUST
  go through one shared writer/reader pair rather than an ad hoc formatter, because
  two formatters that disagree by a fractional second or a `Z` produce rows that
  sort against each other in the wrong order under an `updated_at` ordering.
- **millisecond-write-precision**: The timestamp writer MUST write with millisecond
  precision and an explicit `Z`, so two edits inside the same second still order
  correctly against each other.
- **postgres-form-repair**: The timestamp reader MUST fall back to a repair pass
  when the strict ISO-8601 formatters fail, turning a Postgres wire form — a space
  separator, a two-digit offset, a fraction of any length — into the shape the
  writer itself produces.
- **missing-offset-is-utc**: The repair pass MUST read a timestamp with no zone as
  UTC rather than the local time zone, matching every other value already in these
  columns.
- **formatter-thread-safety**: Access to the shared timestamp writer/reader's
  underlying formatting state MUST be serialized through one exclusive lock (or
  equivalent), since the platform's date-formatter type publishes no thread-safety
  guarantee and the store's read path runs against a pool of concurrent readers.

### Sync Projection

- **pull-only-family**: `content.markdown`, `content.notes`, `content.docs`, and
  `content.papers` MUST be registered as pull-only resources, so a local edit to a
  document or its marker reaches adh only through the store's own outbox, never
  through the generic sync-push path.
- **remote-id-remapping**: Upsert MUST resolve an incoming row's id, and, for marker
  rows, its `markdown_id` foreign key, through the local remote-id table before
  writing, so a row adh identifies by its own minted id lands on the local row
  created before that id was known.
- **partial-patch-delete-guard**: Upsert MUST reject a partial patch whose delete
  columns disagree with the row already on disk; a patch naming only one of the two
  delete columns leaves the other alone rather than being treated as a disagreement.
- **delete-state-normalization**: On a full-row `content.markdown` pull, upsert MUST
  derive one delete fact from both delete columns — a non-null tombstone timestamp
  wins over a falsy boolean flag — and the row is hidden under either signal.
- **truthy-parsing**: The truthy-parsing step MUST treat the database's own truthy
  text spellings, case-insensitively, as true in addition to numeric ones, so a
  text-typed delete flag is recognized the same as a numeric one.
- **frontmatter-claim-release**: Upsert MUST release only the frontmatter claims
  whose incoming value actually differs from what is stored, never a blanket
  release, so a pull that merely echoes back the app's own last write does not
  disown a key the app still owns.
- **number-range-clamping**: The column-encoding step MUST clamp an incoming JSON
  number to a 64-bit signed integer range and store an out-of-range number as a
  lossy floating-point value rather than trapping, since every JSON number decodes
  as a floating-point value.
- **frontmatter-json-guard**: The column-encoding step MUST store a non-JSON
  `frontmatter` value by wrapping it as a JSON string literal rather than dropping
  it or erroring, because the JSON-extract expression index on that column would
  raise a malformed-JSON error on read and wedge the sync cursor permanently if the
  column ever held non-JSON text.
- **unencodable-value-throws**: The column-encoding step MUST throw for an array or
  object value it cannot encode to JSON text rather than binding a null value.
- **orphan-purge-refusal**: The truncate operation MUST refuse to purge
  `content.markdown`, `content.categories`, or `content.keywords` while a dependent
  resource still holds rows and is not itself included in the same purge.
- **required-column-defaults**: Every required-with-no-default column MUST always be
  bound on upsert — a throwaway value on a partial patch that never lands on an
  existing row, or the real value on a full-row pull — so a column with no schema
  default can never be omitted from the write.
- **schema-drift-guard**: The projection's hand-maintained per-resource column lists
  MUST match the live schema's column info at runtime, so the two cannot silently
  drift apart.

### Document Lifecycle & Outbox

- **tenancy-ids-required**: The store's initializer MUST take a customer id and an
  ecosystem id with no defaults, since an empty string is a value the schema can
  store, not an absence the store should silently substitute.
- **db-path-shared-token**: The default database path MUST resolve under one
  token-named directory rather than a name derived from the token's display form, so
  this store and any other consumer of the same token agree on one database file and
  its write-ahead-log state.
- **create-enqueues-payload**: Creating a document MUST, in one write transaction,
  insert the row, add each requested marker row, and enqueue a create operation
  whose payload carries content and marker flags only — category, tags, and title
  are never included, since taxonomy rides its own outbox mutations and title is
  server-derived.
- **list-skips-unreadable-rows**: The document-list read path MUST skip and log a
  row whose timestamp cannot be parsed rather than throwing, on the stated reasoning
  that throwing on a list would remove every other row from the screen; the
  single-document read path MUST throw for the same condition when fetching one row
  by id.
- **update-refuses-authored-drift**: Updating a document MUST throw, naming the
  field and the correct method, if the row being written disagrees with the stored
  visibility, stage, or public route.
- **update-payload-is-content-only**: The shared update path MUST enqueue an update
  operation whose payload carries only content — the server-derived title is never
  part of an outgoing payload.
- **publish-invariant**: Publishing a document MUST refuse an empty route and
  otherwise set visibility and route together in the same update — both halves of
  the invariant move together.
- **delete-is-idempotent**: Deleting a document MUST treat a missing id as success
  rather than throwing not-found — the one lifecycle method where idempotency
  outranks fail-fast, since a retried drain or pull can legitimately call delete on
  a document already gone.
- **delete-tombstones-both-flags**: Deleting a document MUST set both delete columns
  together on the document and on every one of its marker rows.
- **delete-drops-undelivered-create**: Deleting a document MUST drop a still-
  unclaimed pending create/delete pair entirely rather than enqueuing a delete,
  since adh never learned of a document whose create has not yet drained.
- **outbox-order-is-sequence**: The pending-operations read MUST order by the
  dedicated sequence column rather than a creation timestamp, which ties within a
  millisecond, or the operation id, whose sort order is effectively random.
- **outbox-column-corruption-signal**: The pending-operations read MUST throw a
  typed error rather than defaulting a value for an unreadable intent, payload, or
  timestamp column, since the store is the sole writer of these columns and an
  unreadable value can only mean on-disk corruption.
- **opposing-intents-cancel**: The enqueue path MUST cancel a still-pending opposing
  operation outright rather than merging it in place — exactly one operation per
  pair survives — correct only because sends are idempotent and the newest
  instruction always drains last.
- **update-folds-into-pending-create**: The enqueue path MUST fold a queued update
  into a still-unclaimed pending create for the same document rather than adding a
  second operation.
- **drain-reads-remote-id-live**: The queue drain MUST re-read a document's remote
  id immediately before sending each operation rather than trusting a batch
  snapshot, since an update queued behind its own create may only acquire that id
  partway through the drain.
- **drain-preserves-order-on-failure**: The queue drain MUST release the failing
  operation's claim and stop rather than skip ahead when the writer throws, so
  strict sequence order is preserved across retries.
- **drain-clears-stale-claims-first**: The queue drain MUST clear every outstanding
  claim before reading pending operations, on the stated reasoning that a claim
  still standing when a drain begins can only be a pass that was killed mid-send,
  never a pass genuinely still in flight.
- **drain-mutual-exclusion**: one drain at a time is a caller precondition; the
  store does not enforce it (no lock or other exclusion mechanism). Two concurrent
  calls on one store would each clear every claim, read their own snapshot of
  pending operations, claim the same unclaimed operation, and send it to adh twice.

### Taxonomy

- **cycle-refusal**: Adding a category edge MUST refuse an edge that would close a
  cycle, walking downward from the child through a recursive descendant query
  scoped to the ecosystem before inserting.
- **revive-on-conflict**: Adding a category edge, the shared item-assignment path
  backing both category and keyword assignment, and creating a keyword MUST revive a
  tombstoned row on conflict rather than leaving a second, permanently hidden
  duplicate.
- **no-phantom-mutation-on-existing-live-row**: The same revive-on-conflict update
  MUST be a no-op against a row that is already live, so re-adding an edge,
  assignment, or keyword that already exists stages no mutation into the taxonomy's
  own outbox.
- **duplicate-label-refusal**: Creating a keyword MUST throw a duplicate error only
  when the label is held by a still-live keyword — a tombstoned duplicate is revived
  instead of refused.
- **assignment-requires-live-document-and-owner**: The item-assignment path MUST
  throw not-found for a missing or already-deleted document, or a missing category
  or keyword owner, before staging an assignment.
- **category-delete-cascades-edges-and-items-not-documents**: Deleting a category
  MUST tombstone the category row itself plus every edge naming it and every item
  filing a document under it, while leaving the documents themselves untouched.
- **unassign-and-remove-edge-are-idempotent**: Unassigning a category and removing a
  category edge MUST be no-ops — stage nothing, throw nothing — when the assignment
  or edge is already gone.
- **note-count-is-direct-not-transitive**: Category note counts MUST count only
  direct membership, never transitively through child categories, matching a
  folder-badge count's own direct-membership semantics.
- **taxonomy-rides-generic-outbox**: Category and keyword mutations MUST stage their
  pushable fields onto the generic sync outbox in the same transaction as the local
  write, unlike document mutations, which use the dedicated markdown outbox instead
  — taxonomy and documents push through two different queues by design.

