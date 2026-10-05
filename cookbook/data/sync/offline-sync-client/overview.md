
The offline sync client is the client half of adh's offline-first sync: a state
machine that keeps a local mirror of server data current, queues local mutations
while offline, and pushes them when connectivity returns. It is a headless
**engine** — no visual surface — so this recipe omits Appearance and
Accessibility.

The reference implementation splits into two parts:

- **The core** — the platform-neutral logic: the sync engine (the
  pull → reconcile → push cycle), the wire types, the store/transport/
  trigger-source contracts, the observability events, and the client-side
  sync catalog (the adh resource catalog mirrored client-side).
- **The on-disk store** — the persisted mirror (JSON-payload mirror tables,
  an outbox, a conflicts audit) on a durable local database.

The contract is **server-authoritative**. The backend (`/sync/pull`,
`/sync/push`) owns the manifest of syncable resources, the single opaque cohort
cursor, and the outcome of every pushed op; the client mirrors what it is told,
queues what it originates, and never invents behavior the server did not grant.
A client-side catalog is an optimization — it lets a host register the right
resources and refuse pull-only writes before a round trip — but it never
overrides the manifest or a push result.

Each pull returns a **manifest** (the resources the server will sync for this
identity), a batch of **changes** (upserts and delete tombstones), a **cursor**,
and a `hasMore` flag. The client intersects the manifest with its
host-registered set to get the **effective set**, reconciles enrollment
transitions (a resource appearing, disappearing, or bumping schema version),
applies the batch atomically with the cursor, and drains `hasMore`. It then
drains its outbox to `/sync/push`, adopting server rows on conflict and
adopting new versions on apply.

