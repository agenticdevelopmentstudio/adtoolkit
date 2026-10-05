
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lastCycleAt` | `string \| null \| undefined` (ISO 8601) | none (required argument) | Server-clock time of the newest persisted probe. Missing means no probe yet. |
| `generatedAt` | `string \| null \| undefined` (ISO 8601) | none (required argument) | Server-clock time the snapshot was read, re-stamped on every read. |
| `probeIntervalMs` | `number \| null \| undefined` | `undefined`, which gives the 300 000 ms window | The backend's probe interval (derived from `PROBE_INTERVAL_SECONDS` on the server), read off the snapshot. |
| `SNAPSHOT_STALE_FLOOR_MS` | constant | 300 000 | Window floor, compiled in. |
| Very-stale multiplier | literal | 3 | Hardcoded in `snapshotFreshness`; not exported. |
| Window multiplier | literal | 5 | Hardcoded in `snapshotStaleMs`; not exported. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. It has no imports.

