
- **Empty applications list**: an empty applications result MUST render the
  applications listing's configured empty message ("No applications yet.") rather
  than an error (MUST).
- **No schemas to grant**: when the ecosystem has no ungranted buckets, "Add schema"
  MUST fail with the configured no-schemas message rather than presenting an empty,
  unusable picker (MUST).
- **Deleted bucket still referenced by a grant**: a schema grant whose `schemaId` no
  longer matches any bucket MUST still list and remain editable/removable, labeled
  with the configured deleted-schema label (MUST).
- **Boundary: table permissions exactly at the schema ceiling**: a table's submitted
  permissions equal to the schema grant's own permissions MUST be accepted (the
  ceiling check is inclusive of equality) (MUST).
- **Boundary: table permissions exceeding the ceiling by one flag**: MUST be
  rejected with the **table-grant-ceiling-enforcement** message even when only one
  extra flag is set (MUST).
- **Malformed/garbage CRUD wire string**: parsing a CRUD-permissions wire string MUST
  NOT throw on an unrecognized token (e.g. `"x,y,z"`); it parses to a fully-`false`,
  empty value, because parsing is a case-insensitive substring match against
  `{"C","R","U","D"}` with no validation that every token is recognized (MUST).
- **Identifier rename racing a settings save's other field changes**: the settings
  save action performs the rename, the grant re-home, and the field update as three
  sequential awaited calls with no rollback of an earlier step if a later one fails
  — a failed update call after a successful rename and grant re-home leaves the
  application renamed and re-homed but with its display name/consumer kind
  unchanged; the grant-write ordering acknowledges there is "no compensating write"
  for the grant step specifically, and the same is true, undocumented, for the
  trailing update call (MUST NOT roll back — matches the implementation; the
  grants-write-last-writer-wins requirement covers the concurrent-writer variant, this line covers the
  single-writer partial-failure sequence).
- **Concurrent schema-grant writers**: see
  grants-write-last-writer-wins — two overlapping set-schema-grants calls for the same
  application MUST NOT be assumed to compose; the last writer's full-array write
  wins and silently discards the other's change (SHOULD be addressed before this
  component is relied on for multi-writer scenarios; currently undefined).
- **Cancellation**: this component performs no explicit cancellation handling of its
  own; if the underlying platform's concurrency primitives cancel an in-flight call,
  that cancellation is expected to surface through the same error path as any other
  failure — no code in the applications topic distinguishes cancellation from a
  network failure (MUST — this is what the underlying concurrency model guarantees
  with no extra code, not a gap).
- **Offline or unreachable backend**: an offline or transport error thrown by the
  injected data source MUST propagate unchanged through the shared error-wrapping
  step; this component does not retry, queue, or cache a request to paper over the
  failure — a failed call simply throws and the caller decides whether to retry
  (MUST).
- **Empty/blank required text fields**: `displayName` and the "New token" `name`
  field are marked required on their form field, so blank submission is rejected by
  the shared form validator (documented in the `htdv-engine` recipe) before this
  component's own save actions ever run; slug format (not blankness) is the one
  constraint this component itself enforces via the shared slug-format rule (MUST —
  enforcement is delegated, not absent).

