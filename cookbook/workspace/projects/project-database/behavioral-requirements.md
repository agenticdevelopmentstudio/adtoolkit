
### Errors

- **error-cases**: The set of error cases this component can raise MUST be
  exactly four — an open failure, a prepare failure, an execution failure,
  and an invalid-schema failure — each carrying a message string. Only the
  open-failure, prepare-failure, and execution-failure cases are
  constructed and raised by any method described in this file; the
  invalid-schema case is declared here but is raised only by other methods
  of this same component defined in a sibling extension source, out of
  scope for this recipe.

### Identity and concurrency

- **caller-must-synchronize-cross-thread-access**: This component MUST be
  implemented as a plain reference type with no built-in concurrency-safety
  guarantee of its own — no serialization of its own, no automatic thread
  confinement, and no platform-enforced concurrency-safety marker; an
  instance is not safe to share across concurrency domains without the
  caller's own synchronization.
- **single-connection-per-instance**: Each instance of this component MUST
  own exactly one SQLite connection, opened once during construction and
  closed once when the instance is torn down; no method in this file opens
  a second connection or reassigns the stored connection after construction
  completes.
- **connection-serialized-at-the-c-level**: Opening the connection MUST
  pass `SQLITE_OPEN_FULLMUTEX` alongside `SQLITE_OPEN_READWRITE |
  SQLITE_OPEN_CREATE`; this serializes every call into that connection at
  the SQLite C level, so multiple threads MAY call methods on the same
  instance concurrently without corrupting the connection, though calls
  remain otherwise unordered relative to one another beyond that
  serialization.
- **shared-file-busy-timeout**: Opening the connection MUST call
  `sqlite3_busy_timeout(database, 5_000)` so that when another connection
  to the same file — the note store, per this component's own design
  rationale — holds the write lock, a call on this connection blocks for
  up to 5,000 milliseconds waiting for that lock rather than failing
  immediately with `SQLITE_BUSY`.
- **wal-and-foreign-keys-set-per-connection**: Opening the connection MUST
  execute `PRAGMA journal_mode=WAL` and `PRAGMA foreign_keys=ON` every time
  a connection is opened, because SQLite's foreign-key enforcement is a
  per-connection setting that does not persist inside the database file; a
  connection opened without re-issuing `PRAGMA foreign_keys=ON` would
  silently accept writes that violate the cascade relationships declared in
  migration 1.

### Lifecycle

- **init-creates-parent-directory**: Constructing this component MUST
  derive the parent directory from the given path and, when that derived
  directory is non-empty, MUST create it (including any missing
  intermediate directories) before opening the connection.
- **init-order-open-then-migrate**: Constructing this component MUST open
  the connection before running migrations; either step failing MUST
  propagate out of construction and MUST prevent the instance from being
  returned to the caller.
- **default-path-format**: The default path MUST be a dotfolder named
  after the lowercased, alphanumeric-only storage token, directly under the
  given home directory, containing a file literally named `Projects.db`.
- **default-path-defaults**: The default path's parameters MUST default
  `home` to the current user's home directory and `token` to the shared
  storage token used by other stores when the caller supplies neither.
- **checkpoint-truncates-wal**: Checkpointing MUST execute `PRAGMA
  wal_checkpoint(TRUNCATE)`, flushing every committed write from the WAL
  file into the main database file.
- **connection-closed-on-teardown**: Tearing down an instance MUST close
  the SQLite connection when one is open, and MUST NOT attempt to close it
  when none is open.

### Migrations

- **schema-version-constant**: The current schema version constant MUST be
  `4`, matching the highest version number any migration in this component
  inserts into `schema_migrations`.
- **migrations-run-in-one-transaction**: Running migrations MUST wrap the
  `schema_migrations` table creation and every pending migration in a
  single `BEGIN IMMEDIATE TRANSACTION` … `COMMIT`, and MUST issue `BEGIN
  IMMEDIATE` rather than a deferred `BEGIN`, taking the write lock before
  the first schema statement runs rather than on first write.
- **migration-failure-rolls-back**: If any statement during running
  migrations fails, running migrations MUST execute `ROLLBACK`
  (discarding any error from that rollback attempt itself) and MUST
  propagate the original failure to the caller; the file MUST be left
  exactly as it was before running migrations began.
- **migrations-are-sequential-and-append-only**: Running migrations MUST
  run migration 1, migration 2, migration 3, and migration 4, in that
  fixed order, and MUST run each one if and only if the current schema
  version is less than that migration's target version; a migration MUST
  NOT be skipped because a later migration already ran, and MUST NOT run
  twice in the same construction call.
- **schema-version-read**: Reading the schema version MUST return `SELECT
  COALESCE(MAX(version), 0) FROM schema_migrations` as an integer, and MUST
  distinguish "the query found no rows" (yielding `0`) from "the query
  failed" (raising a thrown execution-failure error) rather than collapsing
  both to `0` by substituting a default for any failure.
- **column-existence-check**: Checking whether a column exists MUST query
  `pragma_table_info(?)` bound to the table name, filtered by the bound
  column name, and MUST return true only when the count is greater than
  zero; every migration that adds or drops a column MUST call this first
  and skip the `ALTER TABLE` when the column is already in the state that
  migration would produce.
- **migration001-schema**: Migration 1 MUST create, each guarded by `IF NOT
  EXISTS`, the tables `git_repo` (`id TEXT PRIMARY KEY`, `path TEXT NOT
  NULL UNIQUE`, `name TEXT NOT NULL`, `remote TEXT`, `first_seen REAL NOT
  NULL`, `last_seen REAL NOT NULL`, `last_opened REAL`, `missing_since
  REAL`), `project_setting` (primary key `(repo_id, key)`, `repo_id
  REFERENCES git_repo(id) ON DELETE CASCADE`), `layout_nodes` (a
  self-referencing `parent_id REFERENCES layout_nodes(id) ON DELETE
  CASCADE` and `kind TEXT NOT NULL CHECK(kind IN ('split','leaf'))`),
  `project_tabs`, `project_state` (`repo_id TEXT PRIMARY KEY REFERENCES
  git_repo(id) ON DELETE CASCADE`), and `project_directories`; plus indexes
  `idx_git_repo_name`, `idx_layout_nodes_parent`, `idx_layout_nodes_repo`,
  and `idx_project_tabs_repo`; and MUST insert version row `1` last.
- **migration002-drops-missing-since**: Migration 2 MUST drop the
  `git_repo.missing_since` column only if that column exists on
  `git_repo`, MUST NOT delete any row from `git_repo` regardless of
  whether that row previously had `missing_since` set, and MUST insert
  version row `2`.
- **migration003-pane-state**: Migration 3 MUST add a nullable
  `layout_nodes.thickness_fraction REAL` column when it does not already
  exist, MUST create table `pane_state` with columns `repo_id`, `node_id`,
  `key`, `value` and primary key `(repo_id, node_id, key)`, MUST declare
  `repo_id REFERENCES git_repo(id) ON DELETE CASCADE` on `pane_state`, and
  MUST NOT declare any foreign-key reference on `pane_state.node_id`.
- **migration004-working-directory**: Migration 4 MUST add a nullable
  `project_tabs.working_directory TEXT` column when it does not already
  exist, and MUST insert version row `4`.
- **migration-idempotency**: Re-running construction — and therefore
  running migrations — against a database file that already has every
  migration applied MUST be a no-op that leaves every row unchanged, and
  re-running it against a file whose `schema_migrations` rows were
  partially or entirely deleted while the schema itself is already current
  MUST also complete without error, because every `CREATE TABLE`, `CREATE
  INDEX`, and `ALTER TABLE` statement in every migration is guarded by `IF
  NOT EXISTS` or a preceding column-existence check (`idempotency`).

### Repository CRUD

- **repo-column-set**: Listing every repository, looking one up by id, and
  looking one up by path MUST all select exactly the columns `id, path,
  name, remote, first_seen, last_seen, last_opened`, in that order;
  `missing_since` MUST NOT appear in any `SELECT`, because migration 2 has
  already dropped it from the live schema by the time these operations can
  run.
- **all-repos-ordering**: Listing every repository MUST order its results
  by `name COLLATE NOCASE` ascending, so repositories named "Apple",
  "mango", and "zebra" sort in that order regardless of case.
- **all-repos-includes-every-known-row**: Listing every repository MUST
  return every row currently in `git_repo`; per this component's own
  design rationale, "one [the scanner] did not [find] is deleted, not
  filtered out here" — listing performs no filtering by recency, missing
  state, or any other criterion.
- **repo-lookup-by-id-and-path**: Looking up a repository by id MUST
  filter by `id = ?` bound to the id's string form, and looking up by path
  MUST filter by `path = ?` bound to the given string; both MUST return
  nothing when no row matches.
- **repo-insert-column-set**: Inserting a repository MUST insert all seven
  columns in a single `INSERT` bound in order to the repository's id,
  path, name, remote (nullable), first-seen time, last-seen time, and
  last-opened time (nullable); inserting a repository whose path
  duplicates an existing row's path MUST raise an execution-failure error,
  because `git_repo.path` is declared `UNIQUE` in migration 1.
- **repo-update-column-set**: Updating a repository MUST overwrite `path`,
  `name`, `remote`, `first_seen`, `last_seen`, and `last_opened` for the
  row matching its id, and MUST NOT provide any narrower, per-field update
  operation — per this component's own design rationale, "the caller
  always holds the whole record, so a per-field update API would be a
  second representation of the same knowledge" (`dry`); updating a
  repository MUST NOT change its id.
- **mark-opened-updates-only-last-opened**: Marking a repository opened
  MUST update only the `last_opened` column for the row matching its id,
  defaulting the recorded time to the current time when the caller
  supplies none, and MUST leave `path`, `name`, `remote`, `first_seen`,
  and `last_seen` on that row unchanged.
- **delete-cascades**: Deleting a repository MUST execute `DELETE FROM
  git_repo WHERE id = ?`; per the `ON DELETE CASCADE` foreign keys
  declared on `project_setting.repo_id`, `layout_nodes.repo_id`,
  `project_tabs.repo_id`, `project_state.repo_id`,
  `project_directories.repo_id`, and (from migration 3)
  `pane_state.repo_id`, deleting a `git_repo` row MUST cause SQLite to
  also delete every row in those six tables that references it, with no
  additional statement issued by this operation itself.

### Settings CRUD

- **settings-scoped-per-repo**: Reading a repository's settings MUST
  return every `(key, value)` pair in `project_setting` whose `repo_id`
  equals the given repository id, as a key/value map, and MUST NOT return
  rows belonging to any other repository.
- **setting-single-key-lookup**: Looking up a single setting MUST return
  the value for the given repository-id/key pair, or nothing when no such
  row exists.
- **set-setting-nil-deletes**: Setting a value MUST delete the matching
  `(repo_id, key)` row from `project_setting` when the given value is
  absent, and MUST NOT write an empty-string row in that case; per this
  component's own design rationale, "'unset' and 'set to empty' stay
  different answers" (`explicit-over-implicit`).
- **set-setting-upsert**: Setting a value MUST insert a new `(repo_id,
  key, value)` row when none exists for that pair, MUST overwrite the
  value in place — via `INSERT … ON CONFLICT(repo_id, key) DO UPDATE SET
  value = excluded.value` — when a row for that pair already exists, and
  MUST NOT create a second row for the same `(repo_id, key)` pair.

### Internal SQL plumbing (non-public contract)

- **text-binds-copy-the-string**: Every text bind in this file MUST
  instruct SQLite to copy the string's bytes at bind time rather than
  retain the language runtime's own string storage, so no bound string can
  be read after it has been deallocated.
- **step-loop-fails-on-anything-but-row-or-done**: A row-iteration loop
  MUST treat any step result other than "row" or "done" — including
  `SQLITE_BUSY` — as a thrown execution-failure error, and MUST NOT treat
  such a result as "no more rows"; per this component's own design
  rationale, "a locked database would end the loop early and be
  indistinguishable from a short answer" (`fail-fast`).
- **step-row-fails-on-anything-but-row-or-done**: Stepping a single-row
  query MUST return true on "row", false on "done", and MUST throw an
  execution-failure error for any other status.
- **last-error-message-fallback**: Reading the last error message MUST
  return SQLite's own error text when a connection is open, and MUST
  return the literal string "Database not open" when it is not.

### Malformed row handling

- **malformed-row-handling**: the per-row guard applied when reading repository rows MUST silently omit any row whose id column is not a parseable UUID string or whose path column is null, from every repository-listing and lookup operation alike, with no thrown error, no logged message, and no way for a caller to learn a row was skipped (see Design Decisions).

