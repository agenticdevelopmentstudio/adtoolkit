
### Deadline on the monotonic clock

**Decision**: The deadline is an uptime-nanosecond reading from `DispatchTime`, not wall-clock time.

**Rationale**: The `installEjectionHandler` comment: an NTP step or sleep/wake that moves the wall clock backward must not stop ejection, which "would re-enable the wedge this exists to prevent".

**Approved**: pending

### One armed deadline per thread

**Decision**: Nested calls run inline and inherit the enclosing op's deadline; their own `deadline:` is ignored and they are not metered separately.

**Rationale**: Re-entering GRDB's serial writer from inside a write would deadlock, and inline execution keeps a single `read`/`write` chokepoint without threading `Database` everywhere; the handler reads one thread-local deadline.

**Approved**: pending

### Rollback safety net for self-managed transactions

**Decision**: After a top-level `writeWithoutTransaction`, any transaction still open is rolled back with the deadline already disarmed.

**Rationale**: Interrupting a SELECT while a write is pending leaves the transaction open; if the body swallows the error, the pooled writer would come back mid-transaction and every later write would fail "cannot start a transaction within a transaction" (the scenario in `testSwallowedEjectionInWriteWithoutTransactionDoesNotPoisonPool`).

**Approved**: pending

### Serial queue for in-memory databases

**Decision**: `":memory:"` opens a `DatabaseQueue` rather than a `DatabasePool`.

**Rationale**: A pool needs a real WAL file, and in-memory databases are private per connection, so a reader connection would see an empty database.

**Approved**: pending

### Temp store in memory

**Decision**: Every connection runs `PRAGMA temp_store=MEMORY`.

**Rationale**: Recursive CTEs and ORDER BY spills then never need a temp file that a read-only connection could fail to create.

**Approved**: pending

### Drop, do not substitute, in the token

**Decision**: `token(for:)` removes non-alphanumerics instead of replacing them with `-` or `_`.

**Rationale**: A separator "would only move the problem" — `.coffee-grinder` versus `.coffee_grinder` is a guess every later lookup must repeat correctly.

**Approved**: pending

### Case-folded directory, content-named files

**Decision**: The dotfolder is the lowercased token, and stores name their files for their contents (`Markdown.db`, `Projects.db`), never for the app.

**Rationale**: Capitalization of a display name is cosmetic; renaming "Coffee grinder" to "Coffee Grinder" must not strand the store, and there is then no second spelling of the app name that could fold differently. The same reasoning does not cover a localized `CFBundleName`, which changes the token itself.

**Approved**: pending

### Absent and empty bundle name are the same

**Decision**: `displayName` treats a missing and an empty `CFBundleName` identically, returning `fallbackToken`.

**Rationale**: An empty name gives a user-facing sentence with a hole and a path component that silently collapses onto its parent; resolving it once avoids every call site having to remember.

**Approved**: pending

**Decision**: A failed safety-net rollback is discarded: it raises nothing, logs nothing and is not counted in the metrics.
**Rationale**: The rollback is issued so that its own error is dropped, which leaves a connection still inside a transaction in the pool with no signal. Closing it needs a choice between raising, logging, or counting the failure as an eviction, and a test that forces a failing rollback.
**Approved**: pending

**Decision**: Nesting a call on a different bounded database instance inside an operation is unsupported: it runs inline on the enclosing instance's connection and reports as reentrant.
**Rationale**: The current-connection slot is one per-thread value shared by all instances, so the second instance never gets its own connection. Closing it would take rejecting cross-instance nesting, routing the call to the second instance's own pool, or documenting it as unsupported at the API.
**Approved**: pending

