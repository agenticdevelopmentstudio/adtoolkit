
**Decision**: the settings save action re-homes an application's schema grants by writing
them to the new identifier BEFORE clearing them from the old one, rather than clearing first or
writing both in one call.
**Rationale**: there is no compensating write if the second call
fails; ordering the writes this way means a transient failure on the second (clearing) call merely
leaves a harmless duplicate of the grants under the now-stale old id, whereas the reverse order
would let a transient failure on the second (writing) call lose the grants outright.
**Approved**: pending

**Decision**: a token's plaintext secret is retained in the revealed-secrets store only until
navigation departs from the detail screen currently showing it, enforced by running the
secret-expiry check at the top of every navigation resolution rather than on a timer or a
view-disappear callback.
**Rationale**: retaining the secret for the whole session "made the
notice a lie" — the reveal notice promises the secret disappears once the reader
has navigated away. Tying the check to the navigation path itself, rather than a lifecycle event a
presentation layer would have to remember to call, means the guarantee holds regardless of which
presentation layer drives it.
**Approved**: pending

**Decision**: CRUD-permissions, table-grant, and schema-grant values are kept out of wire
serialization entirely, with the wire shape's translation left to an adapter outside these domain
types.
**Rationale**: this makes it impossible to serialize these domain
types onto the API by accident — a caller reaching for Swift's `JSONEncoder` on a `SchemaGrant`
fails to compile rather than silently producing the wrong wire shape (`{schemaId, crud, tables:
[{tableId, crud}]}` is not what the struct's stored properties would naively encode to).
Platform scope: AppKit/UIKit.
**Approved**: pending

**Decision**: a table's permissions are rejected outright (not clamped or silently ignored) when
they exceed the schema grant's own ceiling, and selecting `"row"` as the permission level is
rejected outright rather than silently treated as `"table"`.
**Rationale**: both are explicit validation errors with user-facing messages
(**table-grant-ceiling-enforcement**, **table-grant-row-level-rejected**) rather than a quiet
downgrade, so the caller always knows why a save did not take effect instead of discovering a
narrower grant than requested only by inspecting it afterward.
**Approved**: pending

**Decision**: schema and table grant edits are persisted by rewriting the application's entire
list of schema grants on every save, rather than a per-field or per-grant PATCH.
**Rationale**: this keeps the write path uniform — one shape of call
(`setSchemaGrants(applicationID:_:)`) handles add, edit, and remove for both schema- and
table-level grants — at the cost of the concurrency exposure covered by the
grants-write-last-writer-wins requirement; it is not documented whether this tradeoff was made knowingly or
because the backend has historically been treated as single-writer-per-application.
Platform scope: AppKit/UIKit.
**Approved**: pending

**Decision**: schema-grant writes are last-writer-wins; the component reads the full grant list, mutates a copy, and writes the whole array back with no optimistic-lock token.

**Rationale**: this contract exposes no version token or compare-and-swap primitive, and whether the backend serializes set-schema-grants calls per application is not known; closing the gap would take a server-side optimistic-lock primitive surfaced through this contract.

**Approved**: pending

