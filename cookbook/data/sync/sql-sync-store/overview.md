
This store is a SQLite-backed implementation of the store contract driven by
the sync engine (see [Sync Engine](adtoolkit://cookbook/data/sync/sync-engine)).
It sits on a bounded, deadline-guarded write-ahead-logged connection pool and
keeps four bookkeeping tables plus one mirror table per registered resource:

- `_sync_state` — the single-row pull cursor.
- `_sync_resources` — the registered resource names and their schema versions.
- `_sync_outbox` — local mutations owed to the server, each `pending`, `inflight` or `quarantined`.
- `_sync_conflicts` — an append-only audit of conflicted pushes.
- one mirror table per resource — `(id, sync_version, deleted_at, data)` with the row's fields stored as a JSON blob in `data`.

An optional projection can claim a subset of resources and store them in typed
tables instead of the JSON mirror; every mirror-touching operation asks the
projection first and falls through to the JSON mirror for unclaimed resources.

Use it when a host needs the offline mirror and outbox to survive restarts.
Beyond the store contract it offers synchronous read helpers (`liveRows`,
`liveRow`, `registeredResources`, `status`) for a daemon or UI, and
transaction-joining variants of `prepare` and `stage` for a store layered on
top of it.

