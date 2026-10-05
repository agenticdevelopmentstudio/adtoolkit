
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `KEY` (module constant) | `string` | `"adh-telemetry-v1"` | The single `localStorage` key; not configurable by the caller. |
| `window.localStorage` (environment) | `Storage` | Browser-provided | The only storage backend; absent in non-browser runtimes, which the adapter treats as "no cache". |
| `cache` (composition root) | `SnapshotCache` | `localCache` | Selected in `telemetry/client.ts`; replacing it swaps the adapter with no other change. |

The adapter takes no constructor parameters, environment variables or feature settings.

