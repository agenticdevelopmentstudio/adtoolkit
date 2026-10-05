
### Session data shapes

- **status-user-shape**: A session user MUST carry `email` (a string), an optional `displayName` that MAY be a string, `null`, or absent, and `role` restricted to exactly `"pending"`, `"viewer"`, or `"admin"`.
- **header-auth-state-shape**: The header-auth state shape MUST carry `user` (an object with `name`, a string) or `null`, plus the optional fields `authLoading` (boolean), `loginHref` (string), `signupHref` (string), and `onLogout` (a zero-argument callback) — the common subset a host header's auth slot takes, declared locally rather than imported.
- **header-auth-source-type**: The header-auth source type MUST be a zero-argument hook type returning the header-auth state shape; the header-auth hook MUST be a stable module-level constant of that type so a host can pass it to its header unchanged.
- **session-query-key**: The session query key MUST be the fixed, order-preserving pair `["status-auth-me"]`, and it MUST be the only key under which the session is cached.
- **session-key-invalidation-precondition**: A login or signup flow that sets the session cookie MUST invalidate the session query key afterwards; this is documented as a caller obligation because the login page caches a fresh signed-out result and the post-login navigation is client-side. This logic does not perform the invalidation itself.

### The session-fetch function

- **auth-me-url**: The session-fetch function MUST request the URL the API client resolves for `/auth/me` (with the default base `"/api"` this is `"/api/auth/me"`).
- **auth-me-transport**: The session-fetch function MUST issue the request through its injectable transport argument (defaulting to the platform's fetch) with no request-options object — a plain `GET` with no custom headers, no explicit credentials option and no abort signal — and MUST NOT route it through the API client's own request method.
- **auth-me-single-request**: Each call to the session-fetch function MUST issue exactly one request; it MUST NOT retry on its own (retry belongs to the session hook).
- **auth-me-non-ok-throws**: When the response's `ok` is false, the session-fetch function MUST reject with an error whose message is `auth/me unavailable (HTTP <status>)`, and it MUST NOT resolve `null` for any non-OK status (the backend never answers this route with a 401, so any non-OK is infrastructure trouble, not sign-out).
- **auth-me-user-resolves**: When the response is OK and its JSON body's `user` field is an object, the session-fetch function MUST resolve that object unchanged.
- **auth-me-signed-out-resolves-null**: When the response is OK and its JSON body's `user` field is `null` or absent, the session-fetch function MUST resolve `null`.
- **auth-me-network-failure-propagates**: When the transport rejects (connection failure, DNS failure), the session-fetch function MUST reject with that same error, unwrapped.
- **auth-me-body-parse-failure-propagates**: When an OK response's body is not valid JSON, the session-fetch function MUST reject with the error the body-parsing step raises.
- **auth-me-no-shape-validation**: The session-fetch function MUST NOT validate the fields of a returned `user` object at runtime; the body is trusted as given, and a `user` missing `email` or carrying an unlisted `role` is returned as-is.

### The session hook

- **session-query-config**: The session hook MUST read the session through one cached query keyed by the session query key, whose query function is the session-fetch function (given the current API-client instance), a staleness window of 60,000 ms, and up to 3 retries (up to four attempts per fetch, with the default exponential backoff).
- **session-query-dedupe**: Every concurrent consumer of the session hook MUST share the single cache entry for the session query key, so simultaneous mounts issue one `/auth/me` request, not one per consumer.
- **session-return-shape**: The session hook MUST return `user` and `isPending`, where `user` is the cached data or `null` when no data exists, and `isPending` is true only while the first load is in flight with no data yet.
- **session-kept-across-errors**: When a refetch fails after data has been cached, the session hook MUST keep returning the last cached user; a failed refetch MUST NOT change `user` to `null`. Sign-out is observed only when a fetch resolves a definitive `null`.
- **session-error-not-exposed**: The session hook MUST NOT expose the query's error or error state to its caller; only `user` and `isPending` are returned.
- **first-load-failure-projection**: When the very first session load fails every retry attempt, the session projection MUST report no user, the same as a definitive signed-out answer, because no cached data exists and the hook exposes no error signal; the header then shows login and signup links. Sign-out otherwise only ever comes from a definitive null user.
- **session-query-defaults-inherited**: The session hook MUST NOT override any caching option beyond those named above; refetch-on-focus, refetch-on-reconnect and cache garbage-collection timing are whatever the host's shared query client defaults are.
- **session-client-resolution**: The session hook MUST resolve its API client through the nearest provider's client, or the same-origin default client when none is mounted.

### The header-auth hook

- **header-signed-out-state**: When the session hook returns a `null` user, the header-auth hook MUST return exactly `user: null`, `authLoading` equal to the session hook's `isPending`, `loginHref: "/login"`, `signupHref: "/signup"`.
- **header-loading-spinner**: While the first session load is in flight, the header-auth hook MUST return `authLoading: true` together with `user: null`, so the host shows a spinner rather than flashing login links.
- **header-signed-in-name**: When a user is present, the header-auth hook MUST return `user.name` equal to `displayName` when it is a non-empty string, and otherwise (`null`, absent, or `""`) equal to `email`.
- **header-signed-in-fields**: When a user is present, the header-auth hook MUST return only `user` and `onLogout`; `authLoading`, `loginHref` and `signupHref` MUST be absent.
- **header-role-not-projected**: The header-auth hook MUST NOT include the user's `role` or `email` (other than as the name fallback) in the returned state.
- **logout-request**: Invoking `onLogout` MUST send one `POST` to `/auth/logout` through the API client's own request method (with the default base, `"/api/auth/logout"`), with no body and no idempotency key; clearing the cookie is the backend's responsibility (see the status server's auth component).
- **logout-navigation**: After the logout request settles — fulfilled with any status, including non-OK, or rejected — `onLogout` MUST navigate the whole page to `"/"`, the public landing page.
- **logout-outcome-ignored**: `onLogout` MUST NOT inspect the logout response's status and MUST NOT invalidate the session query key; the full-page navigation reloads the session from `/auth/me`, so a logout the backend did not honour shows the user still signed in after the reload.
- **logout-rejection-unhandled**: When the logout request rejects, the rejection MUST propagate as an unhandled rejection rather than being caught by `onLogout`.
- **no-switch-href**: The header-auth hook MUST NOT supply a site-switch resolver, so a host's site switcher navigates straight to sibling sites instead of through an adh-SSO redirect.

### Wire DTOs

- **types-module-type-only**: The wire-types module MUST contain only type declarations and type re-exports; it MUST NOT emit runtime code or perform runtime validation of any payload.
- **types-reexports**: The wire-types module MUST re-export a health status, an overall status and a deploy status from the health-classification, overall-status and deploy-status logic, respectively.
- **health-status-values**: A health status MUST be exactly one of `"healthy"`, `"degraded"` or `"down"`; a service status record's `status` and a history check's `status` MUST additionally admit `"unknown"`, while a day's uptime record's `status` MUST NOT.
- **overall-status-values**: An overall status (the type of the status response's `overall` field) MUST be exactly one of `"operational"`, `"degraded"`, `"major_outage"` or `"unknown"`.
- **deploy-status-values**: A deployment record's `status` MUST be a deploy status — one of `"success"`, `"failed"`, `"building"`, `"queued"`, `"canceled"` or `"unknown"` — derived server-side by the status-combining logic; its `buildPhase` MUST be a build phase — one of `"queued"`, `"building"`, `"built"`, `"failed"`, `"canceled"` or `"unknown"` — or `null` when the platform reports no build lifecycle; its `deployPhase` MUST be a deploy phase — one of `"none"`, `"deploying"`, `"deployed"`, `"failed"` or `"unknown"` — and is never null.
- **service-status-dto**: A service status record MUST carry `slug`, `group`, `name`, `url` and `environment` as non-null strings, and `platform`, `deployProject`, `responseTimeMs`, `statusCode`, `error` and `lastCheckedAt` as nullable fields (`platform` here is the explicit deploy target used as a correlation key, not a UI or OS platform).
- **status-response**: The status response MUST carry `overall`, a `services` list of service status records, and a `checkedAt` string.
- **uptime-shapes**: The uptime response MUST carry a `services` list of per-service uptime summaries and a `days` count; each service's uptime summary MUST carry `slug`, `name`, a nullable `uptimePercent`, a `totalChecks` count and a `daily` list of per-day uptime records; each day's uptime record MUST carry `day`, `status` and a nullable `uptimePercent`.
- **deployment-tier-rendering**: A consumer MUST render a deployment record's `tier` field (the logical tier derived server-side by the deploy-environment logic; `null` for a row that deploys no tier, such as a preview) as the deployment's tier, and MUST NOT render `environment` in its place, because `environment` is the provider's promotion target and reads `"production"` for every Vercel project; the client owns no copy of the tier derivation.
- **deployment-nullable-fields**: A deployment record MUST carry `id`, `platform`, `projectName` and `createdAt` as non-null strings, and `environment`, `tier`, `commitHash`, `commitMessage`, `branch`, `commitRepo` (`"owner/name"`), `url`, `errorText` and `liveHost` as nullable strings.
- **deployment-error-text**: A deployment record's `errorText` MUST be the provider's failure reason for a failed deploy (Vercel's `errorMessage` field or a Railway build-log tail) and `null` otherwise, and consumers MUST render it verbatim.
- **deployment-phase-confirmed-at**: A deployment record's `phaseConfirmedAt` MUST be an optional ISO timestamp of when the phases were last confirmed against provider truth; when it is absent (older backend or persisted pre-upgrade rows), consumers MUST treat `createdAt` as its floor.
- **history-shapes**: The history response MUST carry `service` (a string), `hours` (a number) and a `checks` list of history check records; each history check record MUST carry `status`, nullable `responseTimeMs`, `statusCode` and `error`, and a non-null `checkedAt` string.
- **check-state-values**: A check state MUST be exactly one of `"ok"`, `"warn"` or `"error"`, and it MUST be the type of both a check's `state` field and the integrations report's `overall` field.
- **integration-check-shape**: A check MUST carry `id`, `label`, `configured` (boolean), `ok` (boolean), `state` and `detail`, plus the optional `missingEnv` (a list of strings — expected env vars found unset, named exactly; omitted or empty when nothing is missing), `unreachable` (boolean — no HTTP response at all, debounced backend-side) and `correlated` (boolean — unreachable together with other providers in the same run, judged monitor-side connectivity).
- **integrations-response**: The integrations report MUST carry `generatedAt` (a string), `overall` and a `checks` list of checks.

### Concurrency and side effects

- **single-threaded-ordering**: All of this logic's runtime code MUST run without concurrent execution (see Platform Notes for what guarantees this); there is no parallel mutation to order.
- **side-effects**: The only side effects in this logic MUST be the `GET /auth/me` request, the `POST /auth/logout` request, and the full-page navigation to `/`; nothing is written to storage, cookies or logs by this logic.

