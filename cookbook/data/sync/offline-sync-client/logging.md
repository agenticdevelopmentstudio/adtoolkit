
The engine emits an ordered stream of sync events that hosts drain to drive
status UI, retaining at least the most recent 256 events. The full set of
events:

| Event | Payload | Meaning |
|---|---|---|
| `started` | kick reason (`periodic`/`connectivityRestored`/`manual`/`hostSpecific`) | A cycle began. |
| `pulledBatch` | change count, cursor | One pull page applied atomically; cursor advanced. |
| `pushed` | applied count, conflict count, rejected count | One push round-trip resolved. |
| `conflictResolved` | resource name, row id | A conflict adopted the server row locally. |
| `resyncPerformed` | — | Mirror + cursor reset and a full re-pull ran. |
| `resourcesEnabled` | list of resource names | Resources newly in the effective set on a non-fresh cursor (a full resync was performed). |
| `resourcesDisabled` | list of resource names | Resources that left the effective set — mirror purged, outbox quarantined, registration removed. |
| `resourcesSchemaBumped` | list of resource names | Registered resources whose manifest schema version changed — purged + resynced. |
| `unregisteredManifestResources` | list of resource names | Manifest resources the host did not register — ignored, surfaced for observability. |
| `authRequired` | — | HTTP 401: engine paused, awaiting a manual kick. |
| `failed` | message string | Human-readable failure; ops remain queued and a backoff retry is scheduled. |
| `idle` | — | A full pull + push cycle completed with no error. |

**The reachedBackend classification**: a *reachability* signal, not
sync-health. `true` for `pulledBatch`, `idle`, and `authRequired` (the
backend answered — even an HTTP 401 is proof of a live round trip). `false`
for `started`, `pushed`, `conflictResolved`, `resyncPerformed`,
`resourcesEnabled`, `resourcesDisabled`, `resourcesSchemaBumped`,
`unregisteredManifestResources`, and `failed` (which covers both "never
reached the backend" and "the backend errored"). Every event is covered on
purpose, so a new event forces a decision at this call site.

