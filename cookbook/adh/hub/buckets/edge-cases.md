
- **Null and empty input**: An empty or whitespace-only bucket `name` on
  create or settings-save is rejected before this file's own save action
  runs, because `createSpec`/`settingsDetail` both mark the `"name"` field
  `isRequired: true`, and the Forms subsystem's own required-field
  validation (documented in the related HTDV Engine recipe) blocks `save()`
  from invoking the action at all (MUST, by construction of the field). An
  empty or whitespace-only table `name`, by contrast, MUST be caught by
  this file's own save action with `"Every table needs a name."`, because
  `createTableSpec`/`tableDetail` deliberately mark that field
  `isRequired: false` (MUST, see `create-table-requires-a-non-empty-trimmed-name`,
  `table-detail-save-updates-name-only`). An exactly-empty description MUST
  post `nil` metadata; a whitespace-only description is non-empty by this
  check and MUST post as literal whitespace (MUST, see
  `create-bucket-empty-description-becomes-nil-metadata`).
- **Boundary values**: A table count of exactly `1` MUST use the singular
  `"1 table"`; every other count, including `0`, MUST use the plural form
  (MUST, see `table-count-pluralization`). A name that is non-empty after
  trimming but derives an empty SQL identifier — every character stripped —
  MUST be rejected with the dedicated "no letters or digits" message rather
  than silently producing an empty `sqlTableName` (MUST, see
  `table-name-of-unusable-input-is-empty-string`,
  `create-table-rejects-a-name-with-no-usable-characters`).
- **Concurrent access**: the buckets topic is confined to the UI's serial
  execution context, so its own state (the single stored data source
  reference) is not mutated concurrently from another context. The data it depends on can still race across separate
  requests to the server: two overlapping "create bucket" (or "create
  table") calls can both pass this file's client-side duplicate precheck
  before either has landed, because the precheck lists existing state,
  then the create call happens later with no lock in between; this file's
  own defense is that a resulting server-side `HubError.conflict` is caught
  and re-thrown as the same duplicate-name validation message the precheck
  would have produced (MUST, see `create-bucket-conflict-fallback`,
  `create-table-conflict-fallback`, and Design Decisions). `settingsDetail`'s
  save action runs no precheck at all and depends on this same
  conflict-to-validation mapping alone (MUST, see
  `settings-form-conflict-fallback-without-a-precheck`).
- **Error states**: Every operation in the buckets data source is
  asynchronous and fallible; `BucketsTopic` converts every error it does not specifically
  remap (`HubError.notFound` on `get(id:)`, `HubError.conflict` on the
  three create/update save actions) into a `HubError` via `HubError.wrap`
  and re-throws it, so no failure is dropped silently (MUST, see
  `missing-bucket-yields-empty-not-error`,
  `every-other-thrown-error-is-wrapped-not-swallowed`,
  `testFailuresSurfaceAsHubError`). `HTDVCreateAction.perform` (the
  closures passed to `HTDVLevel.createAction`) is non-throwing per its own
  declared signature (documented in the related HTDV Engine recipe), so a
  failure while presenting the "New bucket"/"New table" sheet through
  `FormSheet.present` has no channel back into this file's own error
  handling — it is the sheet's own responsibility.
- **Offline or disconnected state**: None of the three given sources make
  a network call directly or define a timeout, retry, or connectivity-aware
  behavior of their own; every call to `BucketsDataSource` either succeeds
  or throws, and a thrown error surfaces exactly as described under Error
  states above (fact, not a gap — the failure is reported, not lost, just
  with no time bound or automatic retry defined at this layer).

- **table-name-length-unbounded**: deriving a SQL table name from the entered table name MUST strip
  it to ASCII letters, digits, and single-underscore separators and MUST NOT enforce a maximum
  length, neither in the derivation nor in the create-table save action; a sufficiently long name
  therefore yields a SQL table name that a downstream schema-creation step may truncate or reject.

- **bucket-lookup-not-ecosystem-scoped**: resolving a rail path to a bucket MUST fetch the bucket
  by its raw id alone and MUST NOT compare the returned bucket's ecosystem against the ecosystem the
  topic was given before showing, updating, or deleting the bucket or creating tables under it;
  only the listing operations are ecosystem-scoped, so a rail path holding a bucket id from a
  different ecosystem still resolves and the bucket can be edited or deleted. Table rows shown in
  the rail are taken from the ecosystem's own table list, so a table id from another ecosystem does
  not resolve to a detail.

