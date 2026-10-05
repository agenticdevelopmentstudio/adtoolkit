
### Gating (token and cooldown)

- **token-gate**: `fetchCrunchyClusters` MUST resolve `{ ok: true, deploys: [] }` immediately, without issuing any network request, when `env.CRUNCHY_API_TOKEN` is absent, `undefined`, or an empty string.
- **cooldown-gate**: When the `crunchy` provider slot is currently cooling down per `rateLimitedUntil("crunchy")`, `fetchCrunchyClusters` MUST resolve `{ ok: false, deploys: [] }` immediately, without issuing any network request.

### Request and Timeout

- **request-shape**: When neither gate above applies, `fetchCrunchyClusters` MUST issue exactly one `GET` request to the fixed URL `https://api.crunchybridge.com/clusters`, carrying header `Authorization: Bearer` followed by the value of `env.CRUNCHY_API_TOKEN`.
- **https-transport**: The request's origin MUST be the hardcoded literal `https://api.crunchybridge.com`; the transport scheme and host are never caller-configurable through `env`.
- **request-timeout**: The request MUST be bounded by an `AbortController` whose signal aborts after 6,000ms, driven by `setTimeout`, with the timer cleared in a `finally` block regardless of outcome.
- **no-retry**: `fetchCrunchyClusters` MUST make exactly one request attempt per call; it MUST NOT retry a failed, timed-out, or aborted attempt within the same call.

### Response and Error Handling

- **rate-limit-recorded**: When the response status is 429, `fetchCrunchyClusters` MUST call `noteRateLimited("crunchy", ...)` with the response's `retry-after` header value before resolving, so the cooldown slot is set for subsequent calls (including calls from the other thread that shares the cooldown registry).
- **http-error-fails-poll**: When the response's `ok` is `false` (including the 429 case), `fetchCrunchyClusters` MUST log a `console.error` line naming the HTTP status and MUST resolve `{ ok: false, deploys: [] }`.
- **thrown-fetch-fails-poll**: When the `fetch` call throws, the abort fires, or parsing the response body as JSON throws, `fetchCrunchyClusters` MUST catch it, log a `console.error` line naming the caught error, and resolve `{ ok: false, deploys: [] }`.
- **missing-clusters-empty**: When the parsed body's `clusters` field is absent (`undefined`), `fetchCrunchyClusters` MUST resolve `{ ok: true, deploys: [] }`, treating an absent `clusters` field identically to an empty `clusters` array rather than as an error.

### Cluster Mapping

- **cluster-mapping**: For each entry in `clusters`, `fetchCrunchyClusters` MUST produce a `ProviderDeploy` whose `id` is `cr_` followed by the cluster's `id`, whose `platform` is the literal `"crunchy"`, and whose `projectName` is the cluster's `name`.
- **phase-mapping**: Each deploy's `buildPhase` MUST be `null`, and its `deployPhase` MUST be `"failed"` when the cluster's `is_suspended` is `true` or its `state` is one of `failed`, `creation_failed`, or `suspended`; every other `state` value — including `ready`, any routine/transient operation state, and a `state` that is absent or not among the documented set — MUST map `deployPhase` to `"deployed"`.
- **environment-default**: Each deploy's `environment` MUST be the cluster's own `environment` value when present and non-null, and MUST default to the literal `"production"` when the cluster's `environment` is `null` or absent.
- **created-at-fallback**: Each deploy's `createdAt` MUST be the `Date` produced by `toValidDate(c.created_at)` when that call returns a valid `Date`, and MUST fall back to the current time at the moment of mapping (the poll's own execution time) whenever `toValidDate` returns `null` — never an Invalid Date.
- **static-fields**: Each deploy's `commitHash`, `commitMessage`, `branch`, `commitRepo`, and `url` MUST all be `null`, since a Crunchy Bridge cluster record carries no VCS commit or deployment-URL metadata.

