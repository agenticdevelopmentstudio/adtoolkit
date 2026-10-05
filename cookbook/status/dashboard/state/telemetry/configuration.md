
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Poll interval | number (ms), exported constant `TELEMETRY_POLL_MS` | `60000` | Interval the read refetches on while observed. |
| Injected API client | API client | from dependency injection: an overriding client, else the same-origin default with base `/api` | Transport the source reads through. |
| Shared cache (injected) | cache | host cache provider | Owns the shared `telemetry` cache entry, staleness, retry delay and background-refetch defaults; the state overrides only the poll interval, refetch-on-focus and the retry count. |
| Source (composition root) | source | the live source (`GET /telemetry`) | Chosen in the composition root from the available sources (live, or an alternative backend); the alternative reads errors and analytics in parallel and stamps `generatedAt` with the client's current time. |
| Cache (composition root) | cache | the local cache | The persistent-storage adapter chosen in the composition root. |
| Cache key | string | `adh-telemetry-v1` | The persistent-storage key used by the cache adapter. |

