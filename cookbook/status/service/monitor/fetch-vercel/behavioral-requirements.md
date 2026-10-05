
### Signature and No-Op Preconditions

- **env-shape**: `fetchVercelDeployments` MUST accept one `env` object with optional fields `VERCEL_API_TOKEN?: string`, `VERCEL_TEAM_ID?: string`, and `overallBudgetMs?: number`, and MUST return a `Promise` resolving to `{ ok: boolean; deploys: ProviderDeploy[] }`.
- **noop-missing-token**: When `env.VERCEL_API_TOKEN` is falsy (absent or empty string), `fetchVercelDeployments` MUST return `{ ok: true, deploys: [] }` immediately, performing no network call.
- **cooldown-gate-on-entry**: Before any network call, `fetchVercelDeployments` MUST check `rateLimitedUntil("vercel")` (`@agentic-toolkit/deploy-platform/cooldown`, external) and, when it returns a truthy cooldown expiry, MUST return `{ ok: false, deploys: [] }` immediately, performing no network call. This check runs even when the caller's own `guard()` wrapper (`sync.ts`, external) has already checked the identical shared registry before invoking this function, as demonstrated by `provider-cooldown.test.ts`'s "vercel: a 429 poll opens the cooldown; the next poll never touches the network" test, which calls `fetchVercelDeployments` directly, twice, with no `guard` in between.

### Pagination Budget and Page Fetch

- **overall-budget-default**: `fetchVercelDeployments` MUST default `overallBudgetMs` to 12,000 (`DEPLOYS_OVERALL_BUDGET_MS`) when `env.overallBudgetMs` is not supplied.
- **deadline-computed-once**: The overall deadline (`Date.now() + overallBudgetMs`) MUST be computed exactly once, before the pagination loop's first iteration.
- **page-cap**: `fetchVercelDeployments` MUST NOT execute more than 5 (`MAX_PAGES`) page-fetch iterations in one call, regardless of remaining budget or whether the lookback window has been covered.
- **budget-exhaustion-before-page**: At the top of each pagination iteration, `fetchVercelDeployments` MUST compute `remaining` as the deadline minus the current time and, when `remaining <= 0`, MUST set the local `skipped` flag to `true` and stop iterating without starting that page's fetch.
- **per-page-call-timeout**: Each page's fetch MUST be aborted via `AbortSignal.timeout(Math.min(8_000, remaining))` (`DEPLOYS_CALL_TIMEOUT_MS` is 8,000), where `remaining` is recomputed immediately before that page's fetch call.
- **pagination-query-params**: Each page's request MUST target `https://api.vercel.com/v6/deployments` with the query parameter `limit` set to `"100"`; MUST include a `teamId` query parameter equal to `env.VERCEL_TEAM_ID` when it is set; and MUST include an `until` query parameter equal to the previous page's `pagination.next` value once a previous page supplied one (omitted on the first page).
- **auth-header**: Every deployments-list request MUST carry an `Authorization` header of `` Bearer <VERCEL_API_TOKEN> ``.
- **first-page-failure-definitive**: When the page-0 fetch resolves with `res.ok === false`, `fetchVercelDeployments` MUST return `{ ok: false, deploys: [] }` immediately, without attempting or considering any later page. Per the source's own comment, "Page 0 failing is definitive (nothing fetched)."
- **later-page-failure-keeps-partial**: When a fetch for page 1 or later resolves with `res.ok === false`, `fetchVercelDeployments` MUST set `skipped = true` and stop iterating, but MUST keep and map every deployment already collected from earlier successful pages rather than discarding them. Per the source's own comment, "A later page failing must NOT wipe the pages already fetched — keep them and hand back a partial."
- **rate-limit-note-on-429**: Whenever a page-fetch response has status `429` (on any page index), `fetchVercelDeployments` MUST call `noteRateLimited("vercel", res.headers.get("retry-after"))` before falling into the standard first-page/later-page non-ok handling for that response.
- **non-ok-logged**: Whenever a page-fetch response is not `ok`, `fetchVercelDeployments` MUST log `` Vercel API <status> `` via `console.error`.
- **thrown-fetch-first-page**: When the page-0 fetch call throws (including its own `AbortController` firing), `fetchVercelDeployments` MUST catch it, log `` Vercel deployments fetch failed: <message> `` via `console.error` (using the caught error's `message` when it is an `Error`, otherwise its string form), and return `{ ok: false, deploys: [] }`. Per the source's own comment, this is "concise, no stack: an aborted/stalled poll is expected transient noise."
- **thrown-fetch-later-page**: When a fetch call for page 1 or later throws, `fetchVercelDeployments` MUST log the identical message format as thrown-fetch-first-page, set `skipped = true`, and stop iterating while keeping every deployment already collected from earlier pages.
- **lookback-window-stop**: After a page's deployments are collected, `fetchVercelDeployments` MUST compute the minimum `created` value among that page's deployments (when the page returned at least one) and, once that minimum is a finite number no greater than `Date.now() - 1_800_000` (`DEPLOYS_LOOKBACK_MS` is 30 minutes), MUST stop iterating without fetching any further page. Per the source's own comment, "the poll only needs to see deploys new enough to still be in flight; older history is the reconcile's problem."
- **next-cursor-stop**: When a page's `pagination.next` value is falsy, `fetchVercelDeployments` MUST stop iterating (history exhausted), independent of whether the lookback window has been covered.
- **next-cursor-carry**: When a page's `pagination.next` value is truthy and neither the lookback window nor the page cap has stopped iteration, `fetchVercelDeployments` MUST set the cursor used for the next page's `until` parameter to that value.

### Row Mapping

- **row-created-at-validated**: For each raw deployment collected across all fetched pages, `fetchVercelDeployments` MUST compute `createdAt` via `toValidDate(d.created)` (`./provider-deploy`, external); when that call returns `null`, it MUST log `` Vercel deployment <uid> has unparseable created <JSON-stringified value> — skipping `` via `console.error` and MUST exclude that one deployment from the mapped rows, while still mapping every other collected deployment. Per the source's own comment, "an Invalid Date poisons the upsert (failing the whole cycle). Drop THAT deploy, keep the rest — the poll repeats."
- **row-id-prefix**: Each mapped row's `id` field MUST be the literal string `` vc_ `` concatenated with the raw deployment's `uid` field.
- **row-platform-literal**: Each mapped row's `platform` field MUST be the literal string `"vercel"`.
- **row-project-name**: Each mapped row's `projectName` field MUST be the raw deployment's `name` field.
- **row-provider-project-id**: Each mapped row's `providerProjectId` field MUST be the raw deployment's `projectId` field when present, otherwise `null`.
- **row-phases-delegated**: Each mapped row's `buildPhase` and `deployPhase` fields MUST be the two properties of the object returned by `vercelPhases(d.state, d.readySubstate, d.target ?? null)` (`./deploy-status`, external; see the Status Server Monitor Deploy Status recipe for that function's own contract), spread directly into the row with no additional transformation in this file.
- **row-environment**: Each mapped row's `environment` field MUST be the raw deployment's `target` field when present, otherwise `null`.
- **row-commit-hash**: Each mapped row's `commitHash` field MUST be `shortSha(d.meta?.githubCommitSha)` (`./format`, external — a 7-character truncation, or `null` when the source value is absent).
- **row-commit-message**: Each mapped row's `commitMessage` field MUST be `commitFullMessage(d.meta?.githubCommitMessage)` (`./format`, external — the whole message capped at 4,000 characters with trailing whitespace stripped, or `null` when the source value is absent or reduces to empty).
- **row-branch**: Each mapped row's `branch` field MUST be the raw deployment's `meta.githubCommitRef` field when present, otherwise `null`.
- **row-commit-repo**: Each mapped row's `commitRepo` field MUST be the string `` <githubCommitOrg>/<githubCommitRepo> `` when both `d.meta?.githubCommitOrg` and `d.meta?.githubCommitRepo` are truthy, otherwise `null`.
- **row-url**: Each mapped row's `url` field MUST be the raw deployment's `inspectorUrl` field when present; otherwise, when the raw deployment's `url` field is present, it MUST be that value prefixed with the literal `` https:// ``; otherwise it MUST be `null`.

### Return Value

- **deploys-array-partial-kept**: `fetchVercelDeployments` MUST return every successfully mapped row collected before pagination stopped, in the `deploys` array, regardless of whether the returned `ok` is `true` or `false`.
- **ok-composition**: For every branch that reaches the function's final return (i.e. excluding the two first-page-failure early returns), the returned `ok` field MUST be `!skipped` — `true` only when the page cap, a later-page failure, and a later-page throw all never set the `skipped` flag during that call.

### Deploy Error Composition and Fetch

- **compose-deploy-error-signature**: `composeVercelDeployError` MUST accept one object with optional fields `errorMessage?: string | null`, `errorStep?: string | null`, `readyStateReason?: string | null`, and MUST return `string | null` synchronously, performing no network call.
- **compose-deploy-error-reason**: `composeVercelDeployError` MUST compute its reason as `d.errorMessage?.trim() || d.readyStateReason?.trim() || null` — preferring a non-empty, trimmed `errorMessage` over a non-empty, trimmed `readyStateReason`, and returning `null` when neither yields a non-empty string.
- **compose-deploy-error-step-prefix**: When the computed reason is non-null and `d.errorStep?.trim()` is a non-empty string, `composeVercelDeployError` MUST return `` [<step>] <reason> ``; otherwise, when the reason is non-null, it MUST return the reason unprefixed.
- **fetch-deploy-error-noop-token**: `fetchVercelDeployError` MUST return `null` immediately, with no network call, when `env.VERCEL_API_TOKEN` is falsy.
- **fetch-deploy-error-cooldown**: `fetchVercelDeployError` MUST return `null` immediately, with no network call, when `rateLimitedUntil("vercel")` is truthy.
- **fetch-deploy-error-request**: `fetchVercelDeployError` MUST issue a `GET` request to `` https://api.vercel.com/v13/deployments/<encodeURIComponent(uid)> ``, MUST include a `teamId` query parameter equal to `env.VERCEL_TEAM_ID` when set, MUST carry the same `Authorization: Bearer <token>` header as auth-header, and MUST abort the request using the caller-supplied `signal` when provided, or `AbortSignal.timeout(8_000)` otherwise.
- **fetch-deploy-error-429**: When the response status is `429`, `fetchVercelDeployError` MUST call `noteRateLimited("vercel", res.headers.get("retry-after"))` and return `null`, performing no further processing of that response.
- **fetch-deploy-error-non-ok**: When the response is not `ok` and not a `429`, `fetchVercelDeployError` MUST log `` Vercel deployment <uid> detail <status> `` via `console.error` and return `null`.
- **fetch-deploy-error-success**: When the response is `ok`, `fetchVercelDeployError` MUST parse it as JSON and return `composeVercelDeployError` applied to that parsed body.
- **fetch-deploy-error-thrown**: When the fetch call throws (including the request's own abort firing), `fetchVercelDeployError` MUST catch it, log `` Vercel deployment <uid> detail fetch failed: <message> `` via `console.error`, and return `null`.

### Build Log Composition and Fetch

- **compose-build-log-filter**: `composeVercelBuildLog` MUST accept an array of objects each with an optional `payload?: { text?: string | null } | null` field and MUST keep, in their original array order, only the entries whose `payload.text` is a string that is non-empty after trimming.
- **compose-build-log-trim**: For each kept entry, `composeVercelBuildLog` MUST strip only trailing whitespace from its `payload.text` (via the pattern one-or-more-whitespace-characters anchored at the end of the string) before joining, leaving leading and internal whitespace unchanged.
- **compose-build-log-join**: `composeVercelBuildLog` MUST join the kept, trimmed lines with a newline character and return the result; when zero entries qualify, it MUST return `null` rather than an empty string.
- **fetch-build-log-noop-token**: `fetchVercelBuildLog` MUST return `null` immediately, with no network call, when `env.VERCEL_API_TOKEN` is falsy.
- **fetch-build-log-cooldown**: `fetchVercelBuildLog` MUST return `null` immediately, with no network call, when `rateLimitedUntil("vercel")` is truthy.
- **fetch-build-log-request**: `fetchVercelBuildLog` MUST issue a `GET` request to `` https://api.vercel.com/v3/deployments/<encodeURIComponent(uid)>/events `` with query parameters `builds=1`, `direction=forward`, and `limit=-1`; MUST include a `teamId` query parameter equal to `env.VERCEL_TEAM_ID` when set; MUST carry the same `Authorization: Bearer <token>` header as auth-header; and MUST abort the request using the caller-supplied `signal` when provided, or `AbortSignal.timeout(20_000)` (`BUILD_LOG_CALL_TIMEOUT_MS`) otherwise.
- **fetch-build-log-429**: When the response status is `429`, `fetchVercelBuildLog` MUST call `noteRateLimited("vercel", res.headers.get("retry-after"))` and return `null`.
- **fetch-build-log-non-ok**: When the response is not `ok` and not a `429`, `fetchVercelBuildLog` MUST log `` Vercel deployment <uid> events <status> `` via `console.error` and return `null`.
- **fetch-build-log-success**: When the response is `ok`, `fetchVercelBuildLog` MUST parse it as JSON and return `composeVercelBuildLog` applied to that body when it is an array, or applied to an empty array when the parsed body is not an array — a non-array response body MUST NOT throw.
- **fetch-build-log-thrown**: When the fetch call throws, `fetchVercelBuildLog` MUST catch it, log `` Vercel deployment <uid> events fetch failed: <message> `` via `console.error`, and return `null`.

