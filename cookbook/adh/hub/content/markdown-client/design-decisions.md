
**Decision**: bundle `markdownApi`, `schemasApi`, and `taxonomyApi` — two
unrelated domains — under one `markdown/` folder and one `index.ts`.
**Rationale**: schemas.ts's own header comment states this plainly: it is
"the EXISTING (pre-FTD) data layer, mechanically repointed to the renamed
routes/columns so the hub keeps compiling after the buckets DB redesign,"
placed here as a historical accident of a migration, not a domain
relationship to markdown or taxonomy.
**Approved**: pending.

**Decision**: `schemasApi.create` rolls back every table it created plus the
parent bucket if a later table insert fails, but `schemasApi.update`'s
table-reconcile loop has no equivalent compensation.
**Rationale**: `create`'s own comment states the rollback exists to avoid
"orphaning a half-built schema"; `update` has no comment addressing the
same risk for its own multi-step reconcile, which is the asymmetry recorded
as the schemas-update-reconcile-has-no-rollback-or-lock requirement.
**Approved**: pending.

**Decision**: `schemasApi.update`'s table reconcile deletes removed tables
first, awaits them, and only then adds or patches the desired tables,
rather than issuing all the requests in one batch.
**Rationale**: the source's own comment states that batching both
directions would race the backend's unique `(schema, name)` index — e.g.
renaming a table into a name a same-batch delete just freed could 409 if
the insert reaches the database before the delete does.
**Approved**: pending.

**Decision**: `categoryNodes`/`tagNodes` degrade a too-old backend's flat
`items` list into synthetic root nodes (id = name/label) instead of
throwing or returning an empty set.
**Rationale**: the source's comment explains those flat names/labels are
the entire category/tag set such a backend has, so returning `[]` would
blank a rail whose contents arrived in the very same response; the name or
label is the only identity that backend offers and the one every
by-name/by-label filter already uses.
**Approved**: pending.

**Decision**: `SchemaTable.name`'s doc comment documents a "no spaces"
expectation that no code in schemas.ts validates.
**Rationale**: this is a documented but unenforced caller precondition, not
a gap this recipe treats as a contract failure — the only validation the
source actually performs on table names is the case-insensitive duplicate
check in `assertUniqueTableNames`, and it is recorded here as a fact rather
than smoothed over.
**Approved**: pending.

**Decision**: taxonomy writes (rename, file/unfile, delete) go through the
generic CRUD door (`/content/categories`, `/content/category-edges`,
`/content/keywords`) instead of dedicated `/content/markdown/*` routes,
even though `markdownApi.createCategory` posts to the markdown surface.
**Rationale**: the taxonomy.ts header comment states the markdown surface
owns exactly one taxonomy write (category creation) because a nested create
needs the workspace's owning principal resolved for it; every other
taxonomy operation already addresses a row by id, which the generic layer
already does, so republishing them on the markdown surface would just be a
second representation of the same behavior.
**Approved**: pending.

**Decision**: the three clients in this package each use a different
scoping mechanism — `markdownApi` takes a workspace slug via
`opts.workspace`, `schemasApi` takes a plain `ecosystemId` parameter, and
`taxonomyApi` takes no scoping parameter at all.
**Rationale**: each file's own header comment ties this to what its
underlying tables actually support: markdown rows have an
`owner_kind`/`owner_id` column a workspace slug can filter; bucket rows are
owned by an ecosystem directly; and the taxonomy tables carry only a
`customer_id`/`ecosystem_id` ownership stamp with no separate filterable
scope column at all.
**Approved**: pending.

**Decision**: schema lookup-by-id returns `null` for every failure, so a not-found cannot be told apart from a transport or server error.

**Rationale**: the bare catch discards the error and the source does not state what `null` is meant to represent; closing the gap takes narrowing the catch to a 404 and rethrowing everything else, or returning a discriminated result.

**Approved**: pending

**Decision**: schema update has no rollback on a partial failure and no lock or version check against a concurrent update of the same schema.

**Rationale**: the create path has an explicit rollback but the update's table-reconcile loop does not, and the contract exposes no optimistic-lock primitive; closing the gap takes a compensating action for a failed step plus a version check or server-side serialization per schema id.

**Approved**: pending

