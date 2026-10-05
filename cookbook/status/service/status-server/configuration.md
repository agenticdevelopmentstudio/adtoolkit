
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AppDeps.storage` | `Storage` | Required | Pluggable data store abstraction for reading deployment, service, and issue status. |
| `AppDeps.scheduler` | `Scheduler \| undefined` | undefined | Optional periodic monitoring loop. If omitted, `/health` returns `lastCycleAt: null` and staleness is not signaled. |
| `AppDeps.config` | `StatusConfig` | Required | Configuration object passed to every route factory; `createApp` itself reads `appVersion` and `corsAllowedHosts`. |
| `AppDeps.auth` | `AuthGate` | Required | Authentication port implementing principal resolution and tier checks (e.g., view, admin). |
| `AppDeps.seed` | `SeedRoster \| undefined` | `[]` | Optional seed roster (`readonly SeedEndpoint[]`) that `POST /config/seed` creates in an empty configuration; omitted or empty, seed creates only the provider connections. |
| `createScheduler.intervalMs` | `number` | Required | Interval in milliseconds between automatic monitoring cycle ticks. |
| `createScheduler.cycleTimeoutMs` | `number` | `max(3 * intervalMs, 120000)` | Hard timeout in milliseconds for a single cycle. If exceeded, the watchdog releases the lock. Defaults to 3× interval, floored at 2 minutes. |
| `createScheduler.staleAfterMs` | `number` | `max(5 * intervalMs, 300000)` | Duration in milliseconds without a completed cycle before the loop is marked stale. Defaults to 5× interval, floored at 5 minutes. |
| `STATUS_SUMMARY_CACHE_MS` | `30000` | Hardcoded | TTL in milliseconds for the `/public/status-summary` response cache. Public landing page headline status may lag reality by up to this window. |
| `MAX_BODY_BYTES` | `1048576` | Hardcoded | Exported global request body size limit in bytes (1 MB). Applied after CORS and before any route handler via `bodyLimit` middleware. |

