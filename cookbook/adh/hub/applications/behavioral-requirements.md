
**Data source contract**

- **applications-listing**: The list operation MUST return the applications belonging
  to the given ecosystem, asynchronously, and MUST throw rather than return a partial
  or empty result on failure.
- **application-lookup**: The get operation MUST return the single application
  matching the given id, or throw (a not-found is signaled as an error, not an
  optional value).
- **application-creation**: The create operation MUST create and return a new
  application from an application-create body.
- **application-update**: The update operation MUST apply an application-update
  (each of whose `slug`/`displayName`/`consumerKind` fields is independently
  optional) and return the resulting application.
- **application-deletion**: The delete operation MUST remove the application
  identified by the given id.
- **identifier-rename**: The rename-identifier operation MUST issue a `PATCH
  /registry/identifiers/{current}` request with body `{rdid: next}` and MUST throw a
  conflict error when `next` is already taken by another identifier.
- **schema-grants-read**: The schema-grants operation MUST return the full current
  list of schema grants for that application.
- **schema-grants-write**: The set-schema-grants operation MUST replace the
  application's entire schema-grant list with the given array in one call (a
  whole-list write, not a per-grant patch).
- **token-listing**: The tokens operation MUST return the application's token rows
  (never including a plaintext secret).
- **token-creation**: The create-token operation MUST mint a new token and return a
  token-created result, whose `token` field carries the plaintext secret exactly
  once.
- **token-revocation**: The revoke-token operation MUST withdraw the token
  identified by the given token id.

**Data shapes**

- **application-identifier-shape**: An application's `id` MUST be a reverse-domain
  identifier of the form `app.<ecosystem>.<leaf>`; renaming the leaf through the
  rename-identifier operation MUST change this value.
- **application-identifier-prefix**: An application's identifier-prefix value MUST
  return everything up to and including the id's last `.` (e.g. `"app.acme.shop."`
  for `"app.acme.shop.web"`), and MUST return the empty string when the id contains
  no `.`.
- **consumer-kind-decoding**: Decoding a consumer kind MUST accept the wire's free
  `string` field (documented as `maxLength: 16`, no enum) and MUST narrow any value
  that is not `"staff"`/`"developer"`/`"customer"` to `"developer"` rather than
  failing the decode — this is what keeps one unrecognized row from failing the
  whole applications-list decode and blanking the rail.
- **consumer-kind-fallback-values**: when a `consumerKind` string cannot be parsed
  into a recognized consumer kind, the component MUST fall back to one of three
  different defaults depending on the call site: `"developer"` when decoding a wire
  application record, `"customer"` when the "New application" form's `consumerKind`
  value is unparsable, and the application's own current `consumerKind` when the
  "Settings" form's value is unparsable. Because the form's kind options are built
  from the full set of recognized consumer kinds, both form-side fallbacks are
  unreachable through the rendered UI and matter only if a value is missing or
  tampered with.
- **crud-permissions-wire-order**: A CRUD-permissions value's wire form MUST
  serialize to a comma-separated subset of `"C"`, `"R"`, `"U"`, `"D"` in that fixed
  order regardless of the order the flags were set in.
- **crud-permissions-parsing-tolerance**: Parsing a CRUD-permissions wire string MUST
  be case-insensitive, trimming whitespace around each token, and MUST treat any
  unrecognized token as simply absent rather than throwing.
- **crud-permissions-summary-text**: A CRUD-permissions value's summary text MUST
  return `"No access"` when every flag is `false`, and otherwise the enabled flags'
  words (`"Create"`, `"Read"`, `"Update"`, `"Delete"`) joined with `", "` in that
  fixed order.
- **crud-permissions-ceiling-check**: A CRUD-permissions ceiling check MUST return
  `true` only when every flag that is `true` on the value being checked is also
  `true` on the given ceiling.
- **grant-types-are-domain-only**: Table-grant and schema-grant values MUST NOT be
  wire-serializable; this is deliberate — the wire shape (`{schemaId, crud, tables:
  [{tableId, crud}]}`) lives in an adapter outside the domain layer, so it is
  impossible to serialize these domain types onto the API by accident.
- **table-grant-level-is-ui-only**: A table grant's `level` field MUST carry no wire
  counterpart (`"table"` vs. the not-yet-supported `"row"` is a UI-only concept) and
  MUST never be sent to the server.
- **schema-grant-table-keying**: A schema grant's `tables` map MUST be keyed by a
  table's `id` (the wire's `tableId`), never by its `sqlTableName`.
- **application-token-shape**: An application token MUST expose `id`, `name`,
  `prefix`, and an optional `createdAt`, and MUST NOT carry a secret field.
- **application-token-created-shape**: A created-token result (the response to
  minting a token) MUST expose the same fields as an application token plus a
  `token` field holding the plaintext secret.

**Navigation**

- **rail-path-resolution**: The rail path resolver MUST resolve the path in order —
  an application id at position 0, then a section id (`"settings"`, `"grants"`, or
  `"tokens"`) at position 1, then any remaining segments handed to that section's own
  resolver — and MUST return the top-level listing when the path is empty.
- **missing-application-returns-empty**: when looking up the application by id in
  the path throws a not-found error, the rail path resolver MUST return an empty
  result, not propagate the error.
- **errors-wrapped-and-propagated**: any error other than a not-found error from the
  get, list, or any other data-source call MUST be passed through the shared
  error-wrapping step and rethrown — never swallowed.
- **unknown-section-returns-empty**: a section id other than `"settings"`,
  `"grants"`, or `"tokens"` MUST resolve to an empty result.
- **secret-expiry-on-navigation**: every call to the rail path resolver MUST run the
  secret-expiry check first, passing the token id from the path only when the path is
  presently inside that same token's detail (the section id at position 1 is
  `"tokens"` gives the token id at position 2, else none); that check MUST drop the
  currently revealed secret and clear the on-screen-token marker whenever the
  resolved token id differs from it, and MUST leave both untouched when it matches (a
  re-render of the same detail).

**Applications list and create**

- **applications-list-item-mapping**: the applications listing MUST map each
  application to a list item with `id` = the application's `id`, `label` =
  `displayName`, `sublabel` = `id`, an icon keyed by `consumerKind`, and leading to a
  list.
- **create-application-fields**: the "New application" form MUST present, in order,
  a required `displayName` text field, a required `slug` text field validated
  against the shared slug-format rule, and a required `consumerKind` select field
  offering every recognized consumer kind.
- **create-application-slug-lowercased**: the create save action MUST lowercase the
  submitted `slug` before constructing the create body, and MUST trim
  leading/trailing whitespace from `displayName`.
- **create-conflict-messaging**: when creating throws a conflict error, the save
  action MUST throw a validation error reading `An application with identifier
  "{slug}" already exists.` instead of the raw conflict; any other error MUST pass
  through the shared error-wrapping step.

**Application level and settings**

- **application-level-items**: the application-level listing MUST return exactly
  three items, in order: `"settings"` ("Settings", leads to a detail view),
  `"grants"` ("Bucket permissions", leads to a list), and `"tokens"` ("Access
  tokens", leads to a list).
- **settings-form-fields**: the settings detail MUST present `displayName`, `slug`,
  a read-only `identifier`, and `consumerKind`, pre-filled from the current
  application.
- **settings-save-without-rename**: when the submitted `slug` equals the
  application's current `slug`, the save action MUST call the update operation with
  the application's existing id and MUST NOT call the rename-identifier operation.
- **settings-save-with-rename**: when the submitted `slug` differs from the current
  `slug`, the save action MUST call the rename-identifier operation (renaming to the
  identifier prefix plus the new slug) before calling the update operation, and MUST
  target the update at the new id.
- **rename-conflict-messaging**: when the rename-identifier operation throws a
  conflict error, the save action MUST throw a validation error reading `The
  identifier "{next}" is already in use.`.
- **grant-rehoming-write-order**: on a successful rename, the save action MUST read
  the old id's schema grants, write them to the new id, and only then clear the old
  id's grants (write-new, then-clear-old) — never the reverse order, and never a
  single combined write.
- **delete-clears-grants-then-deletes**: the "Delete application" action MUST call
  the set-schema-grants operation with an empty list before calling the delete
  operation.
- **delete-confirmation-text**: the delete action's confirmation text MUST be
  exactly `Delete application "{displayName}"? This cannot be undone.`.

**Bucket permission grants**

- **grants-list-item-mapping**: the schema-grants listing MUST map each schema grant
  to an item labeled with the matching bucket's `name`, or the deleted-schema label
  (`"(deleted schema)"`) when no bucket with that `schemaId` exists among the
  ecosystem's buckets, with `sublabel` set to that grant's permissions summary.
- **add-schema-options-exclude-granted**: the "Add schema" form MUST offer only
  buckets whose id is not already present among the application's current schema
  grants' `schemaId`s.
- **add-schema-default-permissions**: a newly added grant MUST start with read-only
  permissions (`"R"`) and an empty `tables` map.
- **add-schema-requires-selection**: when no ungranted bucket exists, the "Add
  schema" save action MUST throw a validation error reading `No schemas defined yet.
  Create one in the Buckets section first.` without calling the set-schema-grants
  operation.
- **grant-level-item-composition**: the grant-level listing MUST list a `"schema"`
  item ("Schema permissions", divider after, leads to a detail view) followed by one
  item per table in that schema, each labeled with the table's `name` and sublabeled
  with that table's grant summary or `"No access"` when the table has no grant
  entry.
- **schema-detail-fields**: the schema permissions detail MUST present a read-only
  `schema` field plus four toggle fields (`create`, `read`, `update`, `delete`),
  pre-filled from the grant's permissions.
- **schema-detail-deleted-bucket-notice**: when the grant's bucket no longer exists,
  the `schema` field's value MUST append ` — This schema no longer exists. Remove
  the grant, or recreate the bucket.` to the deleted-schema label.
- **schema-save-rewrites-whole-list**: saving the schema detail MUST recompute
  `permissions` from the four toggles, then rewrite the application's entire grants
  list (remove the prior entry for that `schemaId`, append the replacement, call the
  set-schema-grants operation with the full array) — never a partial or per-field
  update.
- **schema-remove-grant**: the schema detail's "Remove grant" action MUST drop that
  schema's grant entirely (the same whole-list rewrite with no replacement) with
  confirmation text `Remove the "{label}" grant? This application will lose access
  to its tables.`.
- **table-grant-ceiling-enforcement**: saving a table's permissions MUST throw a
  validation error reading `"{table.name}" can't exceed the schema's permissions.`
  when the submitted permissions are not within the schema grant's own permissions
  (every enabled flag on the submission must also be enabled on the ceiling).
- **table-grant-row-level-rejected**: selecting `"row"` as the permission level MUST
  cause the save action to throw a validation error reading `Per-row permissions are
  coming soon. Choose "Table".` without persisting anything.
- **table-grant-empty-removes-entry**: when the submitted permissions are empty, saving
  MUST remove that table's entry from the schema grant's `tables` map rather than
  storing an empty-permission table grant.
- **table-grant-level-constant**: every table grant this component persists MUST have
  `level == "table"` — `"row"` is rejected before it can be saved
  (**table-grant-row-level-rejected**) and there is no other path that writes a
  table grant.
- **grants-write-last-writer-wins**: the grant-rewrite logic and the "Add schema" save action
  both read the application's full list of schema grants, mutate an in-memory copy, and write the
  whole array back with no version token, entity tag, or compare-and-swap; two overlapping writers
  (two devices, tabs, or concurrent form submissions against the same application) MAY each read
  the same snapshot, and the second set-schema-grants call then silently discards the first
  writer's change.

**Access tokens**

- **tokens-list-item-mapping**: the tokens listing MUST map each token to an item
  with `label` = `name` and `sublabel` = `"{prefix}… · {formatted createdAt}"`.
- **token-creation-mints-and-reveals-secret**: the "New token" save action MUST call
  the create-token operation and, on success, MUST store the returned token-created
  result's `token` value into the revealed-secrets store, keyed by the created
  token's id.
- **token-reveal-while-current**: the token detail MUST include a read-only `token`
  field (the plaintext secret) and a read-only `notice` field ("Copy this token now
  — you won't be able to see it again.") only while the revealed-secrets store holds
  a value for that token, and MUST set the on-screen-token marker to that token's id
  whenever it does.
- **token-secret-expires-on-navigation**: resolving any path other than that same
  token's detail MUST remove its entry from the revealed-secrets store, so
  navigating to a sibling token or anywhere else and back MUST NOT re-show the
  plaintext secret.
- **token-revoke-clears-secret-and-list**: the "Revoke token" action MUST call the
  revoke-token operation and, on success, MUST remove that token's entry from the
  revealed-secrets store.
- **token-revoke-confirmation-text**: the revoke action's confirmation text MUST be
  exactly `Revoke token "{name}"? Applications using it will lose access.`.

**Authorization errors**

- **authorization-errors-propagate**: an unauthorized or forbidden error thrown by
  the applications or buckets data source MUST propagate unchanged to the caller
  through the shared error-wrapping step rather than being caught, retried, or
  downgraded locally.

