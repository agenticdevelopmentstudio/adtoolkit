
### Signature and No-Op / Cooldown Preconditions

- **env-shape**: `fetchRailwayDeployments` MUST accept one `env` object with optional fields `RAILWAY_API_TOKEN?: string`, `projects?: readonly RailwayProject[]`, `overallBudgetMs?: number`, and `callTimeoutMs?: number`, and MUST return a `Promise` resolving to `{ ok: boolean; deploys: ProviderDeploy[] }`.
- **noop-missing-token**: When `env.RAILWAY_API_TOKEN` is falsy (absent, empty string, or otherwise falsy), `fetchRailwayDeployments` MUST return `{ ok: true, deploys: [] }` immediately, performing no network call.
- **cooldown-gate-on-entry**: Before any network call, `fetchRailwayDeployments` MUST check `rateLimitedUntil("railway")` (`@agentic-toolkit/deploy-platform/cooldown`, external) and, when it returns a truthy cooldown expiry, MUST return `{ ok: false, deploys: [] }` immediately, performing no network call. This check is a self-contained precondition of this function, independent of the caller-side `guard()` wrapper in `sync.ts` (external), which checks the same shared registry before invoking this function during the normal poll cycle; `provider-cooldown.test.ts` exercises this function directly, with no `guard` wrapper, to assert the second of two back-to-back calls makes no additional request.

### Budget

- **overall-budget-default**: `fetchRailwayDeployments` MUST default `overallBudgetMs` to 18,000 (18 seconds, `RAILWAY_OVERALL_BUDGET_MS`) when `env.overallBudgetMs` is not supplied. Per the source's own comment, this sits "under sync's 20s `guard`" (`PROVIDER_POLL_TIMEOUT_MS` in `sync.ts`, external).
- **call-timeout-default**: `fetchRailwayDeployments` MUST default `callTimeoutMs` to 6,000 (`RAILWAY_CALL_TIMEOUT_MS`) when `env.callTimeoutMs` is not supplied.
- **deadline-starts-before-listing**: The overall deadline (`Date.now() + overallBudgetMs`) MUST be computed before the project-listing call, so the listing's own elapsed time counts against the budget. Per the source's own comment, computing the deadline after the listing (an earlier version of this file) let the real worst case run "~6s listing + the full budget + a last in-flight wave" past `guard`'s 20-second cap, discarding the whole poll as unreachable.
- **listing-retry-on-timeout-only**: `fetchRailwayDeployments` MUST retry the project-listing call up to `RAILWAY_CALL_ATTEMPTS` (2) times in total, continuing to a second attempt only when the first attempt's own `AbortController` fired (`listed === null` AND `listController.signal.aborted`) and only while remaining budget is greater than zero; a listing call that answers at all — including an authorized "Not Authorized" GraphQL-error answer — MUST NOT be retried.
- **per-project-retry-on-timeout-only**: For each project, `fetchRailwayDeployments` MUST retry that project's poll (`pollProject`) up to `RAILWAY_CALL_ATTEMPTS` (2) times in total, continuing to a second attempt only when the previous attempt's result was `aborted: true` (this project's own per-call `AbortController` fired) and only while remaining overall budget is greater than zero; a project poll that resolves with any real answer — success or a non-abort error — MUST NOT be retried.
- **budget-exhaustion-before-first-attempt-is-skip**: When remaining overall budget is at or below zero before a project's first poll attempt, `fetchRailwayDeployments` MUST set the module-local `skipped` flag to `true` and MUST return `{ rows: [], error: false }` for that project — this project was never polled, and is not counted as a per-project error.
- **budget-exhaustion-mid-retry-is-error**: When remaining overall budget is at or below zero before a project's retry attempt (attempt greater than 1), `fetchRailwayDeployments` MUST return `{ rows: [], error: true }` for that project — this project WAS polled once and timed out, which is the provider failing the poll rather than a project the poll chose not to start.
- **exhausted-retries-logged-once**: When a project's poll is aborted on every one of its `RAILWAY_CALL_ATTEMPTS` attempts, `fetchRailwayDeployments` MUST log exactly one message, `` Railway <projectId> timed out on all <RAILWAY_CALL_ATTEMPTS> attempts ``, and MUST return `{ rows: [], error: true }`; the per-attempt abort itself MUST NOT be separately logged at this level.

### Project Listing and Fallback

- **prefer-live-listing**: `fetchRailwayDeployments` MUST call `listRailwayProjects(token, signal)` (`@agentic-toolkit/deploy-platform/providers`, external), which enumerates every project the token can see via the root `projects` GraphQL query, preferring it over any caller-supplied list.
- **fallback-to-configured-projects**: When `listRailwayProjects` resolves `null` across all listing attempts, `fetchRailwayDeployments` MUST fall back to `(env.projects ?? []).slice()`.
- **blind-spot-vs-empty-account**: When the resulting project list (live or fallback) has length zero, `fetchRailwayDeployments` MUST return `deploys: []` and MUST set `ok` to the boolean `listed !== null` — `false` when the live listing failed (returned `null`) and no fallback list resolved to a non-empty array either, because holding a token that can see nothing is a blind spot warranting a platform-health issue; `true` when the live listing itself succeeded with a genuinely empty, authorized workspace (`listed` was `[]`, not `null`).

### Bounded Concurrent Fan-Out

- **bounded-concurrency-five**: `fetchRailwayDeployments` MUST poll projects through `mapLimit` (`@agentic-toolkit/deploy-platform/util`, external) with a concurrency limit of 5 (`RAILWAY_PROJECT_CONCURRENCY`), never serially and never fully unbounded. Per the source's own comment, a serial loop made total time `N × 6s`, which with enough projects and a degraded API "alone blows the cycle budget and wedges the whole monitor."

### Per-Project Environment Resolution

- **env-query-precedes-deployments**: For each project, `fetchRailwayDeployments` MUST fetch the `environments(projectId, first)` query and receive a usable response before issuing that project's `deployments` query; the two calls are serial within one project's poll, never concurrent.
- **env-page-size-pinned**: The environments query MUST pin `first: RAILWAY_ENV_PAGE_SIZE` (200) as a GraphQL variable, never left to the server's own default page size.
- **env-fetch-failure-is-project-error**: A non-ok environments HTTP response, a response body carrying GraphQL `errors`, or a response body with no `data.environments` payload at all MUST be logged (`` Railway environments <projectId> <status> `` for the HTTP case, `` Railway environments <projectId> unusable: <messages> `` for the GraphQL-error/missing-payload case) and MUST cause that whole project's poll to return `{ rows: [], error: true, aborted: false }` without ever issuing that project's deployments query. An environments response whose `edges` array is present but empty (`{ data: { environments: { edges: [] } } }`) is NOT this case — it is a genuinely env-less, authorized project and MUST proceed to the deployments query with an empty environment-name map.
- **env-full-page-logged**: When the environments response returns an edge count greater than or equal to `RAILWAY_ENV_PAGE_SIZE`, `fetchRailwayDeployments` MUST log a warning naming the project id and the edge count (matching `FULL page`) because the environment map may be truncated, but MUST NOT treat that project as an error or route it to the platform-unreachable path — the project answered normally.
- **env-name-map-built**: `fetchRailwayDeployments` MUST build an environment-id-to-name map from the environments response's edges (via `buildEnvNameMap`) before fetching that project's deployments.

### Deployment Fetch and Row Mapping

- **deployments-query-first-20**: For each project, `fetchRailwayDeployments` MUST request `deployments(first: 20, input: { projectId })`.
- **deployments-fetch-failure-is-project-error**: A non-ok deployments HTTP response MUST be logged (`` Railway <projectId> <status> ``) and MUST cause that project's poll to return `{ rows: [], error: true, aborted: false }`. A response body carrying GraphQL `errors` MUST be logged (`` Railway <projectId> GraphQL errors: <messages> ``) and MUST produce the same `{ rows: [], error: true, aborted: false }` result.
- **row-created-at-validated**: Each mapped row's `createdAt` MUST be the result of `toValidDate(node.createdAt)` (`./provider-deploy`, external); when that call returns `null`, `fetchRailwayDeployments` MUST log `` Railway deployment <id> has unparseable createdAt <JSON-stringified value> — skipping `` and MUST exclude only that one deployment from the project's rows (via `flatMap` returning `[]` for it), without failing the rest of the project's deployments.
- **row-environment-name-required**: Each mapped row's `environment` MUST be the environment-name map's resolved name for `node.environmentId`; when that id is absent from the map, `fetchRailwayDeployments` MUST log `` Railway deployment <id> references unknown environment <JSON-stringified environmentId> — skipping `` and MUST exclude only that one deployment from the project's rows. A row's `environment` MUST NEVER be the raw `environmentId` UUID or an empty string — either would mint a board target (`railway|<project>|<env>`, external) that matches no roster entry, or collides with an environment-less roster entry.
- **row-id-prefix**: Each mapped row's `id` MUST be the literal string `ry_` concatenated with the Railway deployment's `id` field.
- **row-platform-literal**: Each mapped row's `platform` MUST be the literal string `railway`.
- **row-project-name-from-config**: Each mapped row's `projectName` MUST be the Railway project's configured or enumerated `name` (the value the poll was called with for that project), never a value read from the deployment or its `meta`.
- **row-provider-project-id**: Each mapped row's `providerProjectId` MUST be the polled project's `id`.
- **row-phases-from-status**: Each mapped row's `buildPhase` and `deployPhase` MUST be the two fields of `railwayPhases(node.status)` (`./deploy-status`, external), spread directly onto the row.
- **row-commit-hash-shortened**: When `meta?.commitHash` is a `string`, the mapped row's `commitHash` MUST be `shortSha(meta.commitHash)` (`./format`, external, a 7-character truncation); otherwise it MUST be `null`.
- **row-commit-message-full**: When `meta?.commitMessage` is a `string`, the mapped row's `commitMessage` MUST be `commitFullMessage(meta.commitMessage)` (`./format`, external, the whole message capped at 4,000 characters with trailing whitespace stripped); otherwise it MUST be `null`.
- **row-branch-passthrough**: When `meta?.branch` is a `string`, the mapped row's `branch` MUST be that string unchanged; otherwise it MUST be `null`.
- **row-commit-repo-conditional**: When `meta?.repo` is a `string` AND contains a `/` character, the mapped row's `commitRepo` MUST be that string unchanged; otherwise it MUST be `null`.
- **row-url-dashboard-link**: Each mapped row's `url` MUST be the literal string `https://railway.com/project/` concatenated with the project id — the Railway dashboard link for that project — and MUST NOT be `node.staticUrl` or any other per-deployment live URL.

### Return Value

- **deploys-flattened**: `fetchRailwayDeployments` MUST return every successfully mapped row from every polled project's poll, concatenated into one flat `deploys` array, regardless of whether `ok` is `true` or `false` for the overall call.
- **ok-composition**: For the branch where at least one project was listed and polled, the returned `ok` MUST be `!anyError && !skipped` — `true` only when every polled project's poll succeeded with no unresolved error and no project was left unpolled for lack of remaining budget.

### Build Log Shaping (network-free)

- **build-log-tail-signature**: `buildLogTail` MUST accept an array of `string | null | undefined` and MUST return `string | null`.
- **build-log-tail-trims-and-filters**: `buildLogTail` MUST call `trimEnd()` on each message and MUST drop any message that is `null`, `undefined`, or empty after trimming, before joining the rest.
- **build-log-tail-keeps-last-40**: `buildLogTail` MUST keep only the last `RAILWAY_LOG_TAIL_LINES` (40) surviving lines, joined with `\n`.
- **build-log-tail-caps-chars**: `buildLogTail` MUST cap the joined tail at `RAILWAY_LOG_MAX_CHARS` (4,000) characters, keeping the END of the string and prefixing it with a single `…` character when truncation occurs.
- **build-log-tail-null-when-empty**: `buildLogTail` MUST return `null` when no non-blank lines remain after filtering.
- **build-log-full-keeps-all**: `buildLogFull` MUST accept the same input shape as `buildLogTail`, MUST apply the same trim-and-drop-blank filtering, but MUST keep every surviving line — with no line-count cap and no character cap — joined with `\n`, or `null` when none remain.

### Build Log Retrieval (network)

- **no-build-permanent-sentinel**: The internal `railwayBuildLogMessages` helper, shared by both `fetchRailwayBuildLogTail` and `fetchRailwayBuildLog`, MUST return the internal `NO_BUILD` symbol when the `buildLogs` query's GraphQL `errors` include a message matching `does not have an associated build` (case-insensitive), and MUST return `null` for any other GraphQL error, any non-ok HTTP response, or a thrown fetch — each logged with a distinguishing message (`` Railway buildLogs <deploymentId> <status> ``, `` Railway buildLogs <deploymentId> GraphQL errors: <messages> ``, or `` Railway buildLogs <deploymentId> fetch failed <err> ``).
- **fetch-build-log-tail-contract**: `fetchRailwayBuildLogTail(deploymentId, token, signal)` MUST request `buildLogs` with `limit: 200`, MUST return `RAILWAY_NO_BUILD_TEXT` when the shared helper reports the permanent sentinel, and otherwise MUST return `buildLogTail(messages)` when messages were retrieved or `null` when the helper itself failed.
- **fetch-build-log-full-contract**: `fetchRailwayBuildLog(deploymentId, token, signal)` MUST request `buildLogs` with `limit: RAILWAY_LOG_FULL_LINES` (10,000), MUST return `RAILWAY_NO_BUILD_TEXT` when the shared helper reports the permanent sentinel, and otherwise MUST return `buildLogFull(messages)` when messages were retrieved or `null` when the helper itself failed.
- **no-build-text-constant**: The exported `RAILWAY_NO_BUILD_TEXT` MUST be the literal string `(no build logs — the deployment has no associated build)`.

