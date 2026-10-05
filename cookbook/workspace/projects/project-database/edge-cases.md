
- **Null and empty input (MUST)**: An empty path argument to construction
  produces an empty parent directory, so construction skips creating a
  directory entirely and passes the empty string straight to opening the
  connection; nothing in this file rejects an empty path before that call,
  and an open-failure error is thrown only when the underlying open call
  does not succeed. Similarly, inserting or updating a repository accepts
  a record whose path or name is the empty string with no validation of
  either; the only value this file treats specially is an absent value
  passed to setting a value, which deletes the row rather than storing it
  (see **set-setting-nil-deletes**).
- **Boundary values (MUST)**: Reading the schema version's boundaries are
  exactly less-than-1, less-than-2, less-than-3, and less-than-4 — a
  database already at version 4 runs none of the four migrations; a
  database whose `schema_migrations` table exists but is empty reads as
  version 0 and runs all four. Checking whether a column exists has a
  boundary of "greater than zero matching rows" against
  `pragma_table_info` — i.e. exactly zero or one matching row, since
  SQLite disallows two columns of the same name on one table.
- **Concurrent access (MUST)**: A single instance's one connection is
  opened with `SQLITE_OPEN_FULLMUTEX`, so concurrent calls into the same
  instance from multiple threads cannot corrupt the connection, but are
  otherwise unordered relative to one another beyond SQLite's own
  serialization. A second connection to the same file — this component's
  own design rationale names the note store as sharing it — contends for
  the WAL write lock; `sqlite3_busy_timeout(database, 5_000)` makes a call
  on the losing connection block up to 5 seconds rather than fail
  immediately, and if the timeout still elapses, the row-iteration and
  single-row-step operations surface the resulting `SQLITE_BUSY` as an
  execution-failure error rather than retrying or silently dropping the
  write.
- **Error states (MUST)**: Every SQL failure this file's own code can
  produce — a failed connection open, a failed statement prepare, a
  non-`SQLITE_OK` result from executing a statement, or a step result
  other than "row"/"done" — is surfaced to the caller as a thrown error
  case carrying SQLite's own error text; no method in this file returns a
  sentinel value in place of throwing when a SQL statement fails to
  prepare or execute. The one exception is the malformed-row path (see
  **malformed-row-handling**), which drops a row instead of throwing.
- **Offline or disconnected state**: Not applicable — this component opens
  a local file and makes no network call of any kind; there is no
  connectivity for this component to lose.
- **Missing file or unreachable directory (MUST)**: When creating the
  parent directory fails (for example, a permissions error on the parent
  directory), that thrown error propagates out of construction unchanged;
  construction does not wrap or translate it into one of this component's
  own error cases, so a caller catching only those cases would not catch
  this particular failure.
- **Cancellation and timeouts (MUST)**: No operation in this file is
  asynchronous, and none checks a cancellation flag of any kind; the
  busy-timeout's 5-second wait is the only timeout of any kind in this
  file, and it blocks the calling thread synchronously for up to that long
  with no way for a caller to interrupt it early from this file's own
  code.

