
### Public Operations

- **reconcile-vanished-deploys-signature**: `reconcileVanishedDeploys` MUST accept exactly two parameters — `storage: Storage` and `conn: ProviderConn` — and MUST return `Promise<void>`.
- **expire-unconfirmed-deploys-signature**: `expireUnconfirmedDeploys` MUST accept exactly one parameter — `storage: Storage` — and MUST return `Promise<void>`.
- **reconcile-never-throws**: `reconcileVanishedDeploys`'s returned promise MUST NOT reject on any traced failure path (a candidate-query rejection, a per-row fetch/store rejection, or a per-call timeout) — every one of those is caught internally and logged, never re-thrown.
- **expire-never-throws**: `expireUnconfirmedDeploys`'s returned promise MUST NOT reject when `storage.deploy.expireStaleInFlight` rejects — the rejection is caught internally and logged, never re-thrown.
- **runs-after-upsert-on-full-cycle**: per `sync.ts`'s own call order, on a full sync cycle `reconcileVanishedDeploys` MUST be invoked with the cycle's freshly resolved `conn` only after `storage.deploy.upsertDeployments`, `storage.deploy.learnProjectIds`, and `enrichDeployErrors` have run, and `expireUnconfirmedDeploys` MUST be invoked immediately after that `reconcileVanishedDeploys` call, before `storage.deploy.pruneOlderThanDays`.
- **runs-standalone-on-fast-tick**: on a probe-only tick (`runCycle`'s `opts.skipDeploys` set), `sync.ts` MUST invoke only `reconcileVanishedDeploys(storage, await providerConn(storage, config))` from this module — neither `expireUnconfirmedDeploys` nor `enrichDeployErrors` runs on that tick — before returning early without polling any provider or upserting any deploy.

### Candidate Selection (`reconcileVanishedDeploys`)

- **pollable-platform-filter**: `reconcileVanishedDeploys` MUST compute its candidate platform list (`polled`) as `pollableByIdPlatforms(conn)` filtered to exclude every provider for which `rateLimitedUntil(provider)` returns non-null.
- **no-pollable-platform-short-circuit**: when `polled` is empty, `reconcileVanishedDeploys` MUST return immediately — without pruning `retryAfterFailure`, without calling `storage.deploy.listInFlightCandidates`, and without any provider fetch.
- **backoff-prune-before-query**: before computing parked ids, `reconcileVanishedDeploys` MUST delete every `retryAfterFailure` entry whose `until + RECONCILE_BACKOFF_MEMORY_MS` (600,000ms) is less than or equal to the current time.
- **parked-ids-excluded-in-query**: `reconcileVanishedDeploys` MUST compute `parkedIds` as every remaining `retryAfterFailure` entry whose `until` is still greater than the current time, and MUST pass those ids as `excludeIds` to `storage.deploy.listInFlightCandidates` so a parked row is excluded by the query's own `WHERE` clause rather than filtered out of an already-limited result afterward.
- **candidate-query-shape**: `reconcileVanishedDeploys` MUST call `storage.deploy.listInFlightCandidates` with `platforms` set to `polled`, `excludeIds` set to `parkedIds`, `createdAfterMs` set to the current time minus `RECONCILE_WINDOW_DAYS` (14) days in milliseconds, `fetchedBeforeMs` set to the current time minus `RECONCILE_STALE_MS` (120,000), and `limit` set to `RECONCILE_MAX_PER_CYCLE` (10).
- **candidate-query-failure-fail-soft**: when `storage.deploy.listInFlightCandidates` rejects, `reconcileVanishedDeploys` MUST catch the rejection, log it via `console.error` with `[reconcile] vanished-deploy query failed:` as the first argument and the caught error as the second, and return without calling `mapLimit` or performing any provider fetch.
- **empty-candidates-short-circuit**: when `listInFlightCandidates` resolves an empty array, `reconcileVanishedDeploys` MUST return without calling `mapLimit` or performing any provider fetch.

### Provider Dispatch (`fetchPhasesFor`)

- **id-platform-row-shape**: a candidate value, as returned by `storage.deploy.listInFlightCandidates`, MUST carry exactly two fields — `id: string` and `platform: string` — per its `DeployIdPlatformRow` declaration in `storage/ports.ts`.
- **platform-dispatch-vercel**: `fetchPhasesFor` MUST call `fetchVercelPhasesById` when `row.platform === "vercel"` and `conn.vercel.token` is set, passing `row.id` with a leading `vc_` prefix stripped, `conn`, and the per-call `AbortSignal`.
- **platform-dispatch-railway**: `fetchPhasesFor` MUST call `fetchRailwayPhasesById` when `row.platform === "railway"` and `conn.railway.token` is set, passing `row.id` with a leading `ry_` prefix stripped, `conn.railway.token`, and the per-call `AbortSignal`.
- **platform-dispatch-fallback-null**: for a row whose platform/token combination matches neither branch, `fetchPhasesFor` MUST resolve `null` without making any network call.
- **vercel-detail-request**: `fetchVercelPhasesById` MUST issue a GET to `https://api.vercel.com/v13/deployments/{uid}` (with `uid` URL-encoded) carrying header `Authorization: Bearer {conn.vercel.token}` and the per-call `AbortSignal`, and MUST append a `teamId` query parameter equal to `conn.vercel.teamId` when that value is set.
- **vercel-404-is-gone**: `fetchVercelPhasesById` MUST return the literal string `"gone"` when the response status is 404 — a permanent provider answer that the deployment no longer exists, distinct from a transient failure.
- **vercel-429-suppressed**: when `noteIfRateLimited("vercel", res)` returns true (a 429 response, already recorded into the shared cooldown by that call), `fetchVercelPhasesById` MUST return `null` without any further processing of the response.
- **vercel-non-ok-logged-null**: for any other non-ok response, `fetchVercelPhasesById` MUST log `` `[reconcile] Vercel deployment ${uid} detail ${res.status}` `` via `console.error` and return `null`.
- **vercel-missing-ready-state-null**: when the parsed JSON body has no `readyState`, `fetchVercelPhasesById` MUST return `null`.
- **vercel-phases-delegated**: on a body with a `readyState`, `fetchVercelPhasesById` MUST return `vercelPhases(d.readyState, d.readySubstate, d.target)` unchanged — the phase-mapping contract owned by `adtoolkit://cookbook/status/service/monitor/deploy-status`, not reimplemented here.
- **railway-detail-request**: `fetchRailwayPhasesById` MUST call `gqlPost(token, "query($id: String!) { deployment(id: $id) { status } }", signal, { id })`, passing the deployment id as a GraphQL variable rather than interpolating it into the query string.
- **railway-429-suppressed**: when the response status is 429, `fetchRailwayPhasesById` MUST return `null` without logging — `gqlPost` has already recorded the cooldown for that response.
- **railway-non-ok-logged-null**: for any other non-ok response, `fetchRailwayPhasesById` MUST log `` `[reconcile] Railway deployment ${id} detail ${res.status}` `` via `console.error` and return `null`.
- **railway-deployment-null-is-gone**: when the parsed body's `data` key is present and `data.deployment` is exactly `null` (the query succeeded and the provider reports no such deployment), `fetchRailwayPhasesById` MUST return `"gone"`.
- **railway-status-delegated**: when `data.deployment.status` is a present string, `fetchRailwayPhasesById` MUST return `railwayPhases(status)`; when `data` is absent (including a GraphQL `errors` response) or `data.deployment.status` is absent, it MUST return `null`.

### Per-Row Bounding

- **per-call-timeout**: for each candidate row, `reconcileVanishedDeploys` MUST create an `AbortController`, start a `setTimeout` that calls `controller.abort()` after `RECONCILE_CALL_TIMEOUT_MS` (8,000) milliseconds, pass `controller.signal` into `fetchPhasesFor`, and MUST clear that timer in a `finally` block regardless of whether the fetch settled, rejected, or was aborted.
- **bounded-concurrency**: `reconcileVanishedDeploys` MUST process candidate rows via `mapLimit` with a concurrency limit of `RECONCILE_CONCURRENCY` (4), so no more than 4 candidate rows are ever being fetched at the same instant within one call.

### Persistence and Backoff

- **park-on-no-phases**: when `fetchPhasesFor` resolves `null` for a row, `reconcileVanishedDeploys` MUST call `parkFailure(row.id, Date.now())` and MUST NOT call `storage.deploy.markDeployGone` or `storage.deploy.markDeployPhases` for that row.
- **terminalize-on-gone**: when `fetchPhasesFor` resolves `"gone"` for a row, `reconcileVanishedDeploys` MUST call `storage.deploy.markDeployGone(row.id)`, log `` `[reconcile] ${row.id} gone at provider → canceling in-flight lifecycle(s)` `` via `console.log`, and MUST delete `row.id` from `retryAfterFailure`.
- **persist-fresh-phases**: when `fetchPhasesFor` resolves a `Phases` object for a row, `reconcileVanishedDeploys` MUST call `storage.deploy.markDeployPhases(row.id, phases)` and MUST delete `row.id` from `retryAfterFailure`, treating the by-id fetch as authoritative and overwriting both lifecycle columns unconditionally.
- **park-on-throw**: when `fetchPhasesFor`, `markDeployGone`, or `markDeployPhases` rejects for a row, `reconcileVanishedDeploys` MUST catch that rejection inside that row's `mapLimit` callback, call `parkFailure(row.id, Date.now())`, log `` `[reconcile] ${row.id} phase fetch/store failed:` `` via `console.error` with the caught error as the second argument, and MUST NOT let the rejection propagate out of `mapLimit` or affect the processing of any other row.
- **backoff-escalation**: `parkFailure(id, now)` MUST set `fails` to the previous entry's `fails + 1` when a previous `retryAfterFailure` entry for `id` exists and its `until + RECONCILE_BACKOFF_MEMORY_MS` (600,000ms) is greater than `now`, and MUST set `fails` to `1` otherwise; it MUST then set `until` to `now + min(RECONCILE_BACKOFF_BASE_MS * 2^(fails - 1), RECONCILE_BACKOFF_MAX_MS)` — that is, `60,000ms` doubling on each consecutive escalating failure, capped at `300,000ms` (5 minutes).
- **backoff-memory-window**: a row's escalation count MUST reset to `1` on its next failure once its previous backoff's `until + RECONCILE_BACKOFF_MEMORY_MS` (600,000ms) has passed without a further failure for that id, per `backoff-prune-before-query`'s deletion of expired entries.
- **terminal-writes-bump-fetched-at**: per the libsql implementation of `markDeployGone` and `markDeployPhases`, both MUST set the row's `fetchedAt` to the current time on every write, so a row confirmed still building defers its next reconcile candidacy by `RECONCILE_STALE_MS` from that write, not from its original stale `fetchedAt`.

### Terminal Expiry (`expireUnconfirmedDeploys`)

- **expire-collapses-stale-in-flight**: `expireUnconfirmedDeploys` MUST call `storage.deploy.expireStaleInFlight(EXPIRE_UNCONFIRMED_MS)` (21,600,000ms / 6 hours), which — per the libsql implementation — collapses only the in-flight build/deploy lifecycle column(s) of a row unconfirmed (by `fetchedAt`) for at least that long to `unknown`, leaving any already-settled sibling lifecycle column on that same row untouched.
- **expire-logs-nonzero-count**: when `expireStaleInFlight` resolves a count `n` greater than `0`, `expireUnconfirmedDeploys` MUST log `` `[reconcile] ${n} in-flight deploy row(s) unconfirmable for 6h+ → unknown` `` via `console.log`; when `n` is `0` it MUST NOT log anything.
- **expire-fail-soft**: when `storage.deploy.expireStaleInFlight` rejects, `expireUnconfirmedDeploys` MUST catch the rejection, log it via `console.error` with `[reconcile] expiry sweep failed:` as the first argument and the caught error as the second, and MUST NOT rethrow.
- **expiry-not-created-at-windowed**: `expireStaleInFlight`'s predicate MUST NOT filter by the row's `createdAt`/`RECONCILE_WINDOW_DAYS` — a row's age since creation MUST NOT exempt it from expiry; only its `fetchedAt` staleness against `EXPIRE_UNCONFIRMED_MS` gates it, so a row that aged past the reconcile window (and so can no longer be re-fetched by id) is still reachable by expiry.
- **expired-value-is-overwritable**: because the shared `columnOverwritableSql` predicate treats a column value of `unknown` as overwritable (in the same way an in-flight value is), a fresh provider truth arriving later for that column — a poll upsert, a subsequent by-id re-fetch from this module, or a webhook — MUST replace an `unknown` value written by `expireStaleInFlight`, so a false expiry self-heals the next time any of those sources reports.

### Credential Handling

- **tokens-used-for-auth-only**: `fetchVercelPhasesById` and `fetchRailwayPhasesById` MUST use `conn.vercel.token`, `conn.vercel.teamId`, and `conn.railway.token` only to construct the outbound `Authorization` header or GraphQL call to the corresponding provider, MUST NOT read any of the three from `process.env` or any source other than the `conn` parameter, and MUST NOT log or persist any of the three values.

### Ordering and Concurrency

- **module-state-scope**: `retryAfterFailure` MUST be a module-scope `Map<string, Backoff>` — worker-thread-local and unpersisted across a process restart, per the source's own comment on its declaration.
- **test-hook-only**: `_resetReconcileBackoff` MUST clear `retryAfterFailure` and MUST exist only to reset module state between tests; neither `sync.ts` nor `cycle-runner.ts` call it from any production code path.
- **intra-call-concurrency-bound**: within one `reconcileVanishedDeploys` call, up to `RECONCILE_CONCURRENCY` (4) candidate rows' fetches MAY run concurrently via `mapLimit`, each with its own `AbortController`/timer pair and targeting a distinct row id, so no two concurrent fetches within one call can write to the same storage row or share a timeout.
- **thread-context**: `reconcileVanishedDeploys` and `expireUnconfirmedDeploys` run on whichever thread their caller (`runCycle` in `sync.ts`, via `runMonitorCycle` in `cycle-runner.ts`) is executing on — the monitor's own worker thread for a scheduled cycle, or the API thread when invoked from there; this file makes no thread-affinity assumption of its own beyond running to completion on whichever thread called it.

