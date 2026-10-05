
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` (parameter) | `Storage` | required, caller-supplied | The storage port providing `storage.deploy.listInFlightCandidates`, `markDeployGone`, `markDeployPhases`, and `expireStaleInFlight`; this file never constructs or configures a storage implementation itself. |
| `conn` (parameter, `reconcileVanishedDeploys` only) | `ProviderConn` | required, caller-supplied | Resolved provider connections (`@agentic-toolkit/deploy-platform/conn`), carrying `conn.vercel.token`/`conn.vercel.teamId` and `conn.railway.token`, used to gate and authenticate the per-provider by-id fetches. |
| `RECONCILE_WINDOW_DAYS` (module-internal constant, not exported) | `number` | `14` | Recency window in days; only in-flight rows created within this window are reconcile candidates. |
| `RECONCILE_MAX_PER_CYCLE` (module-internal constant, not exported) | `number` | `10` | Maximum candidate rows queried and fetched per `reconcileVanishedDeploys` call. |
| `RECONCILE_CONCURRENCY` (module-internal constant, not exported) | `number` | `4` | Maximum concurrent in-flight fetches passed to `mapLimit`. |
| `RECONCILE_CALL_TIMEOUT_MS` (module-internal constant, not exported) | `number` | `8_000` | Per-row fetch deadline enforced via `AbortController`/`setTimeout`. |
| `RECONCILE_STALE_MS` (exported constant) | `number` | `120_000` (2 min) | How long an in-flight row may go unconfirmed before it becomes a reconcile candidate; also doubles as the natural retry cadence for a genuinely still-building row, since every check bumps `fetchedAt`. Deliberately shorter than the deploy poll's default 5-minute interval. |
| `RECONCILE_BACKOFF_BASE_MS` (exported constant) | `number` | `60_000` (1 min) | Base delay for a failing row's exponential backoff. |
| `RECONCILE_BACKOFF_MAX_MS` (exported constant) | `number` | `300_000` (5 min) | Cap on a failing row's escalating backoff delay. |
| `RECONCILE_BACKOFF_MEMORY_MS` (exported constant) | `number` | `600_000` (10 min) | How long a lapsed backoff's escalation count is remembered past its expiry before a fresh failure resets to the base delay. |
| `EXPIRE_UNCONFIRMED_MS` (exported constant, `expireUnconfirmedDeploys`) | `number` | `21_600_000` (6 hours) | How long an in-flight lifecycle column may stay unconfirmed before `expireUnconfirmedDeploys` collapses it to `unknown`. |
| `retryAfterFailure` (module-level state, not a parameter) | `Map<string, Backoff>` | empty at module load | Per-row backoff registry (`{ until: number; fails: number }`); worker-thread-local and unpersisted across a process restart. |

