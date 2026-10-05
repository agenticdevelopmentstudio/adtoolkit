
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` (parameter) | `Storage` | required, caller-supplied | The storage port providing `storage.deploy.listFailedWithoutError` and `storage.deploy.setErrorText`; this file never constructs or configures a storage implementation itself. |
| `conn` (parameter) | `ProviderConn` | required, caller-supplied | Resolved provider connections (`@agentic-toolkit/deploy-platform/conn`), carrying `conn.vercel.token`/`conn.vercel.teamId` and `conn.railway.token`, used only to gate and authenticate the per-provider fetches this file dispatches to. |
| `ENRICH_WINDOW_DAYS` (module constant) | `number` | `14` | Recency window in days; only failed deploys created within this window are candidates. Not configurable per call and has no environment override in this file. |
| `ENRICH_MAX_PER_CYCLE` (module constant) | `number` | `8` | Maximum candidate rows queried and enriched per call. Not configurable per call. |
| `ENRICH_CONCURRENCY` (module constant) | `number` | `4` | Maximum concurrent in-flight fetches passed to `mapLimit`. Not configurable per call. |
| `ENRICH_CALL_TIMEOUT_MS` (module constant) | `number` | `8_000` | Per-row fetch deadline enforced via `AbortController`/`setTimeout`. Not configurable per call. |

