
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` (parameter) | `Storage` | none — caller-supplied, required | The persistence port every read/write in this file goes through. Opened and owned entirely by the caller; this file never manages a connection. |
| `config` (parameter) | `StatusConfig` | none — caller-supplied, required | Threaded into `providerConn`, `enumerateDeployProjects`, and `reconcileBoardLedger`. This file itself reads provider credentials only indirectly, through `providerConn(storage, config)`'s resolved `conn`. |
| `opts.skipDeploys` (parameter) | `boolean \| undefined` | `undefined` (falsy → full cycle) | `true` runs only the cheap probe (steps 0-5) plus the bounded in-flight deploy reconcile and the ledger write, then returns; the expensive provider-poll/prune/retire phase (steps 6-8) is skipped entirely for that call. |
| `PROVIDER_POLL_TIMEOUT_MS` (module constant) | `number` | `20_000` | Hard cap every `guard`-wrapped provider poll races against; not configurable from `StatusConfig` or the environment. |
| deploy retention window (`pruneOlderThanDays` argument) | `number` (literal) | `90` | Hardcoded in this file's call; the row-level retention this cycle itself performs on the `deployments` table (distinct from the `health_checks`/`metrics_hourly` retention owned by `MaintenanceStore`). |
| `EMPTY_DEPLOYS` / `EMPTY_PROJECTS` (module constants) | `{ ok: false, deploys: [] }` / `VercelProjectsResult`-shaped | fixed literal | The fallback shapes `guard`, and the token-gating ternaries, substitute for a provider that is unconfigured, unreachable, rate-limited, or timed out — every downstream consumer of a poll result reads the same shape whether the provider ran or not. |
| provider tokens (`conn.vercel.token`, `conn.cloudflare.token`, `conn.railway.token`, `conn.crunchy.token`) | `string \| undefined`, resolved via `providerConn(storage, config)` (external) | none | Presence alone (not value) gates whether a provider is polled at all this cycle (provider-poll-token-gated); the token value itself is only ever passed to that provider's own fetcher, never inspected or logged by this file. |

