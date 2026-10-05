
- **Decision**: tune WAL, a 5-second `busy_timeout`, and `synchronous = NORMAL`
  for every embedded-file connection, never for a remote libsql/Turso one.
  **Rationale**: the source comment states this directly — WAL lets the
  monitor worker write while the API server reads (and vice versa) instead
  of the default rollback journal's whole-file locking; `busy_timeout`
  makes a second writer wait instead of failing `SQLITE_BUSY` on
  contention; `NORMAL` pairs with WAL to fsync on checkpoint rather than
  per-commit, trading a small durability window against app crashes for
  avoiding per-insert fsyncs under the monitor's write volume. A remote
  connection manages its own journaling, so applying any of this to it
  would be a no-op at best and a wrong assumption at worst.
  **Approved**: pending
- **Decision**: make `checkpointWal` fail-soft (`busy: true`, no throw)
  rather than retry or force a checkpoint through a live reader.
  **Rationale**: the source's own multi-paragraph comment documents the
  production incident this addresses — a checkpointed-but-never-shrunk WAL
  sidecar can sit at a high-water mark set by the largest transaction ever
  run (a multi-million-row retention sweep, in this case), and only
  `TRUNCATE` mode reclaims that disk space; but a `busy` result means a
  live reader (the API server's own connection) still holds the old WAL,
  so forcing the issue would risk breaking that reader rather than simply
  waiting for the next maintenance pass to try again.
  **Approved**: pending
- **Decision**: keep `deployments.status` as a nullable, otherwise-unused
  column instead of dropping it in this migration.
  **Rationale**: the column comment states the reason directly — dropping
  it immediately would break still-live old code mid-rollout, during the
  window where migrations auto-apply ahead of every instance being updated
  to read `buildPhase`/`deployPhase` instead; the comment marks it for
  removal "in a later migration" once that cutover is complete.
  **Approved**: pending
- **Decision**: declare `onDelete: 'cascade'` foreign keys on
  `monitoredSites`/`monitoredEndpoints` even though libSQL over HTTP does
  not enforce them.
  **Rationale**: the schema comment states this is deliberate
  documentation of intent for a future connection mode that would enforce
  it, while today's application code (`db/config.ts`, external to these
  two files) performs the cascading delete itself; declaring the
  relationship in the schema keeps the intent visible and the relational
  query builder aware of the join, even though SQLite-over-HTTP will not
  act on it.
  **Approved**: pending
- **Decision**: default `platformHealthState.configured`/`reachable` and
  `deployments`/`monitoredEndpoints` boolean flags to `true` rather than
  leaving them nullable or defaulting to `false`.
  **Rationale**: each default-`true` column's comment frames it as a
  deliberate, low-risk guess about rows that predate the column, not a
  claimed fact — an unconfigured platform being guessed "reachable" only
  delays a poll from correcting it, and the `reachable` migration
  specifically backfills `false` where `consecutiveFailures > 0` to avoid
  suppressing a live incident. This is recorded here as the tradeoff it
  is, not defended as free of cost.
  **Approved**: pending

