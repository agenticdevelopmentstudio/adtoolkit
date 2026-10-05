
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cb` | `(snap: LiveSnapshot) => void` (`subscribeLive` parameter) | none, required | The subscriber callback registered for future publishes. |
| `snap` | `LiveSnapshot` (`publishSnapshot` parameter) | none, required | The snapshot handed to every subscriber unchanged. |
| `maxAgeMs` | `number` (`recentSnapshot` parameter) | none, required | Caller-chosen staleness window; `routes/stream.ts`'s `OPENING_CACHE_MS` (1500) is the one caller in this package, external to this file. |
| `storage` | `Storage` (`emitLiveUpdate` parameter, injected port) | none, required | Passed straight through to `buildLiveSnapshot` for the reads a fresh snapshot needs. |
| `config` | `StatusConfig` (`emitLiveUpdate` parameter, injected) | none, required | Passed straight through to `buildLiveSnapshot`. |
| `COALESCE_MS` | module constant | `150` | Fixed debounce/coalesce window in milliseconds; not configurable per call, by environment, or by `StatusConfig`. |

