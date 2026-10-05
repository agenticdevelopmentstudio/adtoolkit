
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` (in `client.ts`) | `TelemetrySource` | `SOURCES.live` (`liveSource`) | Where the client reads snapshots. Change it to `SOURCES.turso` to serve from the database. This is a code edit, not a runtime setting |
| `cache` (in `client.ts`) | `SnapshotCache` | `localCache` | Where the client persists the last snapshot |
| `api` (argument to `get`) | `StatusApiClient` | none (the caller supplies it) | The injected HTTP client. It resolves `/telemetry`, `/errors` and `/analytics` against its base path |
| `KEY` (in `local-cache.ts`) | string | `adh-telemetry-v1` | The localStorage key. The `-v1` suffix versions the stored shape |

