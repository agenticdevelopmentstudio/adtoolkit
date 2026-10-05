
### activity.ts — `GET /activity`

- **activity-cursor-pairing**: `before` (an ISO-parseable timestamp) and
  `beforeId` MUST be supplied together; supplying only one of the pair MUST
  respond 400.
- **activity-cursor-empty-id-allowed**: an empty-string `beforeId` paired with
  a non-empty `before` MUST be accepted — it is the stall-escape cursor that
  `pageActivity` itself mints when a page boundary lands mid-timestamp-tie; an
  empty-string `before` MUST NOT be accepted (it is not a valid ISO
  timestamp) and MUST respond 400.
- **activity-cursor-range-check**: the parsed cursor timestamp MUST be a safe
  integer in `[0, MAX_CURSOR_MS]` (`MAX_CURSOR_MS = 8.64e15`, the largest
  timestamp `Date` can represent); a cursor outside that range or that fails
  to parse MUST respond 400.
- **activity-limit-clamping**: an absent, non-numeric, or out-of-range
  `limit` query parameter MUST fall back to `MAX_ACTIVITY_ROWS`; a numeric
  `limit` MUST be clamped into `[1, MAX_ACTIVITY_ROWS]` rather than rejected.
- **activity-cold-path**: this route reads via `createActivityPageReader`
  against persisted rows only; it is not on the SSE live-update path, and a
  client polls it explicitly for history beyond the board's live tail.

### auth.ts — `authRoutes`

- **auth-pre-seam-mounting**: `authRoutes` are documented as mounted BEFORE
  the app-wide `requireAuth` seam — every route here MUST be reachable
  without a session or bearer token.
- **auth-signup-normalization**: `POST /auth/signup` MUST lowercase the
  submitted email before any existence check or insert.
- **auth-signup-duplicate-detection**: signup MUST respond 409 both when a
  pre-check finds an existing user for the normalized email, and when the
  insert itself fails a unique constraint (`isUniqueViolation`) — the second
  path exists because the pre-check and insert are not one atomic step, so a
  concurrent signup race MUST still surface as 409, not a 500 or a silent
  duplicate.
- **auth-login-timing-safety**: `POST /auth/login` MUST run `verifyPassword`
  against a real stored hash when the user exists, and against
  `DUMMY_PASSWORD_HASH` when the user does not exist, so that an unknown
  email and a known email with a wrong password take a comparable code path;
  both failure cases MUST respond 401 with the same message.
- **auth-logout-dual-revocation**: `POST /auth/logout` MUST revoke a bearer
  token when the `Authorization` header carries one with the `sts_` API-token
  prefix, AND MUST revoke/clear the session cookie when one is present; it
  MUST respond 200 `{ ok: true }` regardless of which credential (or neither)
  was present.
- **auth-me-never-unauthenticated**: `GET /auth/me` MUST NOT respond 401
  under any input; it MUST resolve a session first, fall back to a bearer
  token's principal shape second, and otherwise respond 200 with
  `{ user: null }`.
- **auth-rate-limits**: `/auth/login` MUST be rate-limited (max 10 per
  window) and `/auth/signup` MUST be rate-limited (max 5 per window),
  independently of each other.
- **auth-oauth-mounting**: `authRoutes` MUST mount `githubRoutes` at its own
  root so GitHub OAuth callback handling shares the same pre-seam exposure.

### auto-configure.ts — `POST /auto-configure`

- **auto-configure-admin-gate**: the route MUST require admin per-route
  (`requireAdmin` applied to this one route, not via a blanket `app.use('*')`
  as `config.ts`/`users.ts` do) because this sub-app is mounted alongside
  other, non-admin routes at the same base path.
- **auto-configure-opt-out-respected**: a project already recorded as an
  ignored project (matched by platform+projectName) MUST be excluded from
  matching/creation on this and every subsequent call until explicitly
  un-ignored.
- **auto-configure-ignore-persistence**: entries in the request's `ignore`
  array MUST be persisted (step 1) before matching/creation runs, so a
  project ignored in the same request that also appears elsewhere in the
  payload is honored within that same call.
- **auto-configure-create-target-validation**: a non-null `create` object
  MUST validate `groupId` (required) and `forceGroup` (optional boolean) via
  `autoConfigureBody`; a missing or malformed `create` MUST respond 400.
- **auto-configure-lite-adapter**: `performAutoConfigure` MUST talk to
  persistence exclusively through `statusAdapter` — a direct, in-process
  `StatusAddApi` implementation backed by `storage.config` calls (not an HTTP
  round-trip) — keeping the matching/creation engine itself HTTP-agnostic and
  reusable outside this route.
- **auto-configure-site-purge-on-delete**: `statusAdapter.deleteSite` MUST
  use the purging delete (removing the site's endpoints with it), not a
  bare row delete, so a re-run never leaves orphaned endpoints under a
  deleted site.
- **auto-configure-skip-dedup**: repeated skip entries for the same
  project+reason MUST be deduplicated in the response's `skippedDetail`
  while preserving first-seen order; the `skipped` count itself MUST NOT be
  deduplicated (it reflects every skip event, not distinct reasons).
- **auto-configure-reconcile-sweep**: successful creation/wiring MUST trigger
  a board-ledger reconcile so the board reflects newly-added sites/endpoints
  without waiting for the next scheduled cycle.
- **auto-configure-partial-failure**: a run is not transactional. Per-project failures on the project axis (`runAutoConfigure`) and per-endpoint failures on the endpoint axis (`wireMatchingEndpoints`) are caught one item at a time and reported in `skipped`/`skippedDetail` with the error message as the reason, while every other item still proceeds and earlier writes stay committed. When a created site's endpoint insert fails, the engine deletes that site so its (group, slug) cannot 409 later runs; a failed rollback delete is not reported separately, and the original error is what lands in `skippedDetail`. A storage failure in the ignore persist, enumeration or classify steps is not caught and fails the whole request, with any ignores already written left in place.

### badge.ts — `GET /status/badge.svg`

- **badge-overall-remapping**: the route MUST re-expand the compact
  snapshot's 3-state `overall` (`healthy`/`degraded`/`down`) to the 4-state
  `OverallStatus` vocabulary used elsewhere (`operational`/`degraded`/
  `major_outage`, plus `unknown`) via `overallFromSnapshot` before rendering.
- **badge-error-fallback**: any failure while building the underlying
  snapshot MUST be caught and MUST fall back to rendering the badge with
  `overall = 'unknown'` rather than propagating an error response — a status
  badge embedded in a third-party README MUST always render an SVG, never a
  5xx.
- **badge-caching**: the response MUST carry `Cache-Control: public,
  max-age=60`.
- **badge-svg-shape**: the SVG MUST be built via `buildSvg` in the
  shields.io label/value badge style, keyed off the remapped overall status.

### board.ts

- **board-read-always-fresh**: `GET /board` MUST derive its response fresh on
  every call (`deriveBoard(await readBoardFacts(...), nowMs)`) rather than
  serving a cached board — it is the client's sole source for the current
  Problems list, Activity tail, and top-level indicator, so staleness here
  would directly mislead the dashboard.
- **board-reconcile-admin-gate**: `POST /board/reconcile` MUST require admin,
  applied per-route (matching `auto-configure.ts`'s rationale, not a blanket
  `app.use('*')`).
- **board-reconcile-skip-on-empty-roster**: the reconcile call MUST pass
  `skipOnEmptyRoster: true` so an empty monitored roster (e.g. mid-migration,
  or a fresh instance) is treated as "nothing to reconcile" rather than as
  "everything just went down."
- **board-reconcile-idempotent**: repeated calls with no roster/status change
  between them MUST produce no additional opened/resolved transitions —
  the route is documented as safe to call repeatedly (e.g. from a manual
  admin action or a retry).
- **board-reconcile-can-alert**: the route MUST be treated as capable of
  synchronously triggering on-call alerting (open/recovered transitions) on
  the request thread — a caller MUST NOT assume this endpoint is read-only or
  side-effect-free.

### config.ts

- **config-blanket-admin-gate**: every route under this sub-app MUST require
  admin via a blanket `app.use('*', requireAdmin)` — unlike `board.ts` and
  `auto-configure.ts`, none of these mutating config endpoints is exposed at
  a shared, partially-public base path.
- **config-peer-url-validation**: a peer's `baseUrl` MUST pass
  `isValidPeerBaseUrl`, and MUST NOT resolve to this instance's own base URL
  (`assertNotSelfPeerUrl`); either failure MUST respond 400.
- **config-peer-duplicate-detection**: inserting a peer whose `baseUrl`
  duplicates an existing peer's MUST respond 409 (`isDuplicatePeerError`
  mapped to `DUPLICATE_PEER_MESSAGE`), not a raw DB constraint error.
- **config-peer-token-redaction**: every peer object returned by any route in
  this file (list, create, patch) MUST pass through `redactPeer` — the raw
  token MUST never be present in a response; a `hasToken` boolean MUST stand
  in its place.
- **config-mutation-reconcile-sweep**: every mutating route that can change
  which sites/endpoints/groups exist (creates, patches, and especially
  deletes on site-groups, sites, endpoints, and integrations) MUST inline-call
  `reconcileBoardLedger(storage, config)` with no `skipOnEmptyRoster` guard —
  these routes are the ones that CAUSE any resulting empty roster, so unlike
  `board.ts`'s reconcile route they MUST always sweep.
- **config-endpoint-retirement-atomicity**: deleting an endpoint MUST use
  `retireEndpoint`, which atomically deletes the endpoint and, if that leaves
  its parent site with no remaining endpoints, deletes the now-empty site in
  the same operation.
- **config-ignored-project-key-parsing**: `DELETE` on an ignored-project MUST
  parse a compound `platform|projectName` key from the id parameter and
  MUST respond 400 if the key does not split into exactly two non-empty
  parts.
- **config-seed-idempotence**: `POST /seed` (`runSeed`) MUST create groups,
  sites, and endpoints from the seed roster only when they do not already
  exist (matched by name), and MUST create a provider integration only when
  that provider's token environment variable is set AND no integration for
  that provider already exists — a second call with the same roster and
  environment MUST NOT create duplicates.
- **config-openapi-contract**: this file's Zod insert/patch schemas MUST stay
  in lockstep with the generated OpenAPI document that the project's own
  `openapi.test.ts` pins.

### cron.ts

- **cron-blanket-admin-gate**: `/cron/*` MUST require admin via
  `app.use('/cron/*', requireAdmin)`.
- **cron-refresh-blocking**: `POST /cron/refresh` MUST await
  `scheduler.runNow()` before responding — the caller's request does not
  complete until that refresh cycle has finished.
- **cron-maintenance-bounded**: `POST /cron/maintenance` MUST call
  `storage.maintenance.runMaintenance()` and MUST return its `done: boolean`
  verbatim; `done: false` means the prune is bounded per call and a backlog
  remains for the next invocation, not that the call failed.

### deploy-logs.ts — `GET /deployments/:id/log`

- **deploy-log-unknown-id**: an unknown deployment id MUST respond 404 before
  any provider fetch is attempted.
- **deploy-log-timeout**: the underlying provider fetch MUST be bounded by
  `LOG_TIMEOUT_MS` (25,000 ms) via `AbortController`.
- **deploy-log-degrade-not-error**: `fetchLogFor` dispatching to an
  unsupported platform, or to a platform with no configured credential, MUST
  return `null` for the log rather than throwing — the response body MUST
  still be `{ ...row, log: null }` with 200, not an error status; a genuine
  fetch failure (timeout, provider error) MUST also degrade to `log: null`
  rather than failing the whole response, since the row's own fields
  (`errorText`, summary) remain informative on their own.
- **deploy-log-indistinguishable-degrade**: the response MUST NOT
  distinguish "platform doesn't support logs" from "credential missing" from
  "provider fetch failed" — all three collapse to the same `log: null`, by
  design (the honest answer is the same either way: no log to show).

### device.ts — RFC 8628 device authorization flow

- **device-code-hashing**: both `device_code` and `user_code` MUST be stored
  only as `sha256Hex` digests; no plaintext code MUST be persisted.
- **device-user-code-alphabet**: `generateUserCode` MUST draw from
  `USER_CODE_ALPHABET`, which excludes vowels and the digits/letters
  `0`/`1`/`O`/`I`/`U`, via rejection-sampled `randomInt`, formatted as two
  groups of four (`XXXX-XXXX`).
- **device-user-code-normalization**: `hashUserCode` MUST trim and uppercase
  the input before hashing, so a user typing the code in any case or with
  incidental whitespace still matches.
- **device-start-response**: `POST /auth/device` MUST purge expired grants
  before creating a new one, MUST be rate-limited (max 10 per window), and
  MUST respond with `device_code`, `user_code`, `verification_uri`,
  `interval` (`POLL_INTERVAL_SEC` = 5), and `expires_in`
  (`DEVICE_TTL_MS` / 1000 = 900 seconds), with `Cache-Control: no-store`.
- **device-token-poll-errors**: `POST /auth/device/token` MUST be
  rate-limited (max 30 per window) and MUST map grant state to the RFC 8628
  error vocabulary: an unknown or expired code responds `{ error: 'expired'
  }` (an expired-but-still-present row MUST also be deleted at that point);
  a denied grant responds `{ error: 'denied' }`; a pending grant polled
  faster than `POLL_INTERVAL_SEC` since its last recorded poll responds
  `{ error: 'slow_down' }` WITHOUT advancing the last-poll timestamp; a
  pending grant polled at a valid interval responds
  `{ error: 'authorization_pending' }` and DOES advance the timestamp.
- **device-token-single-use-consumption**: an approved grant MUST be consumed
  atomically and exactly once (`consumeApproved`) — a second poll of an
  already-consumed grant MUST NOT re-mint or re-return the token; a
  successful consumption MUST look up the token's role and expiry and return
  the raw token value, with `Cache-Control: no-store`.
- **device-approval-session-required**: every route in `deviceApprovalRoutes`
  MUST require a session user (`requireSessionUser`) and MUST respond 403 to
  a caller with no session user — this excludes both AUTH_DISABLED anonymous
  callers and bearer-token principals from approving/denying/listing device
  grants.
- **device-pending-lookup**: `GET /auth/device/pending` MUST respond 400 if
  `user_code` is missing, MUST reap an expired grant it finds (deleting it)
  and respond 404 for it rather than returning stale pending state, and MUST
  respond 404 for any user code with no live grant.
- **device-approve-race-guard**: `POST /auth/device/approve` MUST mint the
  new token at the approver's own session tier, MUST guard the status
  transition to `approved` on the grant still being `pending` at write time,
  and — if that guard loses a race to a concurrent approve/deny — MUST
  delete the token it had just minted (no orphaned, unreachable token left
  behind) and respond 409.
- **device-deny-guarded**: `POST /auth/device/deny` MUST use the same
  guarded-transition pattern as approve, responding 404/409 under the same
  conditions.

### fleet.ts — `GET /fleet`

- **fleet-composition**: the route MUST compose `buildSnapshot` (from
  `reads.ts`) with `assembleFleet` (from `../peers/fleet`) and MUST return the
  assembled fleet-member list as its sole responsibility — it holds no
  independent business logic of its own.

### hooks.ts — provider deploy webhooks

- **hooks-pre-seam-mounting**: provider webhook ingest routes MUST be mounted
  before the app-wide `requireAuth` seam — a provider cannot present a
  session cookie or bearer token, so authentication here is the signature
  check, not the seam.
- **hooks-ownership-three-way**: `ownedBySite` MUST return one of
  `'owned'`, `'not-owned'`, or `'unknown'` — never collapse to a boolean —
  and MUST return `'unknown'` (logging the underlying error) rather than
  throwing when the roster read itself fails, so the caller can fail closed.
- **hooks-fail-closed-on-unknown-ownership**: both webhook handlers MUST
  respond 503 when ownership resolves to `'unknown'`, MUST respond 200 with
  `{ ok: true, ignored: 'not owned by a site' }` when it resolves to
  `'not-owned'`, and MUST proceed to persist only on `'owned'`.
- **hooks-signature-before-parse**: `POST /hooks/vercel` MUST read the raw
  request body as text and verify the HMAC-SHA1 signature
  (`verifyVercelSignature`) BEFORE attempting to JSON-parse it; a bad
  signature MUST respond 401 and MUST NOT parse the body at all.
- **hooks-secret-unconfigured**: either webhook route MUST respond 503 if its
  verification secret is not configured, rather than accepting an
  unverifiable payload.
- **hooks-unparseable-avoids-retry-storm**: a JSON parse failure on a
  signature-valid Vercel payload MUST respond 200 with `{ ok: true, ignored:
  'unparseable' }`, not an error status — an error status would make the
  provider retry a payload that will never parse.
- **hooks-unmapped-event-ignored**: a well-formed payload whose event type
  has no mapping (`mapVercelDeployEvent`/`mapRailwayDeployEvent` returning
  null) MUST respond 200 with `{ ok: true, ignored: true }`.
- **hooks-railway-shared-secret**: `POST /hooks/railway` MUST accept the
  shared secret via either a `?token=` query parameter OR an
  `x-webhook-secret` header (`verifySharedSecret`), and MUST respond 401 if
  neither matches.
- **hooks-persist-fail-soft**: a persistence failure
  (`storage.deploy.upsertDeployments`) on an otherwise-owned, verified event
  MUST be caught and logged, MUST NOT fail the webhook response, and MUST
  NOT prevent the event from being pushed to the live buffer — the poll
  cycle and buffer together cover a lost persist.
- **hooks-derivation-fail-soft**: `runReconcile`'s call into
  `reconcileBoardLedger`/alert-flushing MUST be caught and logged; a
  derivation failure MUST NOT turn a successfully-verified, successfully-
  persisted webhook into an error response.
- **hooks-reconcile-single-flight-coalescing**: `reconcileGate` MUST ensure
  at most one reconcile pass runs at a time per `hooksRoutes` instance, and
  MUST coalesce concurrent arrivals during a running pass so that every
  arrival is covered by either the in-flight pass or one guaranteed
  follow-up pass (the "cleared before the pass" queued-flag pattern) —
  never dropped.
- **hooks-live-buffer-and-broadcast**: a successfully-owned event MUST be
  pushed onto the live update buffer and MUST trigger `emitLiveUpdate` so
  subscribed SSE clients see it without waiting for their next poll.
- **hooks-cloudflare-absence-is-deliberate**: the absence of a
  `/hooks/cloudflare` route is a documented, pre-approved decision (source
  comment: `adh-ui-allow: defer — Cloudflare has no per-deploy webhook;
  polling covers it; approved by mike 2026-06-26`), not an oversight —
  Cloudflare deploy status is covered by the existing poll cycle instead.

### read-body.ts

- **read-body-canonical-helper**: `readValidatedBody<T>(c, schema)` MUST be
  the one shared JSON-read-and-Zod-validate helper for new route code; a
  JSON parse failure MUST respond 400 with an `'invalid JSON'`-style message,
  and a schema validation failure MUST respond 400 with a message that
  includes the Zod issue detail.
- **read-body-partial-adoption**: this helper is documented as replacing
  three near-identical `parse`/`parseBody`/`readJson` variants that had
  drifted across the route files; as of these 17 files, `device.ts` and
  `tokens.ts` use it, while `auth.ts` and `config.ts` retain their own local,
  behaviorally-equivalent copies rather than having been migrated onto it —
  this is a recorded fact about the current codebase, not a behavioral
  inconsistency (all variants still produce an equivalent 400 on bad input).

### reads.ts — the read-side snapshot/live/history API

- **reads-live-owner-bound-first**: `buildLiveSnapshot` MUST resolve
  `owners`/`projects` via board ownership BEFORE running the deploy query, so
  the deploy query is bounded to owned projects rather than scanning
  unbounded provider history.
- **reads-live-buffer-overlay**: `deploymentDtos` MUST merge persisted rows
  with the in-memory live-buffer webhook overlay by id, with the buffer's
  version winning the merge for any id present in both — a webhook that
  arrived after the last DB read must not be shadowed by a stale persisted
  row.
- **reads-problems-single-producer**: `boardProblems` MUST be the sole
  producer of the derived Problems list used across `/live`, `/status`, and
  `/snapshot`; a documented decision explicitly rejects splitting out a
  cheaper "problems-only" path to avoid two divergent derivations of the
  same list.
- **reads-snapshot-error-redaction**: `buildSnapshot`'s `problems` list MUST
  exclude any Problem whose `target` parses as an error target
  (`parseErrorsTarget(p.target) !== null`) — error Problems carry internal
  GlitchTip project identifiers and exception titles in their `name`/`detail`
  that MUST NOT reach `/public/status-summary`'s anonymous readers; this
  filter is documented as a deliberate, reversible disclosure decision, not
  an incidental omission.
- **reads-deploy-cache-atomicity**: `refreshAndEnumerateDeployProjects` MUST
  treat "refresh provider data" and "enumerate projects from it" as one
  inseparable, cached unit (`PROVIDER_READ_CACHE_MS` = 30,000 ms); a Vercel
  read failure during refresh MUST fail the whole call closed rather than
  returning a partially-refreshed enumeration.
- **reads-deploy-projects-shared-cache**: `GET /deploy-projects` MUST share
  its cache across concurrent callers via `cachedSingleFlight`, and MUST
  bypass the cache only when `?fresh=1` is supplied.
- **reads-history-slug-required**: `GET /history` MUST respond 400 if no
  `slug` query parameter is supplied.
- **reads-history-hours-clamp**: `GET /history`'s `hours` parameter MUST be
  clamped to `[1, 168]`.
- **reads-uptime-days-clamp**: `GET /uptime`'s `days` parameter MUST be
  clamped to `[1, 365]`.
- **reads-response-history-clamps**: `GET /response-history`'s `hours`
  parameter MUST be clamped to `[1, 2160]` and its `buckets` parameter MUST
  be clamped to `[1, 240]`.
- **reads-endpoint-wiring-paused-claims**: `listEndpointsForWiring` MUST
  include paused endpoints, not only active ones (it deliberately is not
  `listActiveEndpoints`) — a paused monitor still claims its project for
  wiring/correlation purposes so re-enabling it does not silently create a
  duplicate wiring.
- **reads-correlate-ignore-vs-wire-granularity**: `correlateDeployProjects`
  MUST treat "ignored" as project-level and "wired" as per-environment
  (keyed by `deployTargetKey`), with a Railway host-membership fallback when
  an exact target key does not match.

### stream.ts — SSE and manual-check trigger

- **stream-opening-frame**: `GET /live/stream` MUST reuse a snapshot built
  within the last `OPENING_CACHE_MS` (1,500 ms) if one exists, and otherwise
  build a fresh one for the opening frame; a build failure for the opening
  frame MUST be caught and MUST send a null-data opening frame rather than
  failing the stream's setup.
- **stream-subscribe-before-send**: the route MUST call `subscribeLive`
  BEFORE sending the opening frame, closing the race window in which an
  update could arrive between "snapshot taken" and "subscribed" and be
  missed entirely.
- **stream-heartbeat**: the stream MUST send a heartbeat (`: ping`) every
  `HEARTBEAT_MS` (25,000 ms) to keep intermediary proxies from closing an
  idle connection.
- **stream-lifetime-cap**: the stream MUST be forcibly closed after
  `STREAM_MAX_MS` (600,000 ms / 10 minutes), requiring the client to
  reconnect — this bounds how long a revoked session's credential can keep
  streaming after revocation.
- **stream-cleanup-idempotent**: cleanup (unsubscribe, clear heartbeat/cap
  timers) MUST run exactly once per connection regardless of which of
  `cancel()`, an `enqueue` failure, or the request's `abort` signal triggers
  it first.
- **stream-check-requires-scheduler**: `POST /live/check` MUST respond 503 if
  no scheduler is configured.
- **stream-check-debounce**: `POST /live/check` MUST debounce per caller
  (session user id, or `'anon'`) using `MANUAL_MIN_MS` (3,000 ms); a call
  within the floor MUST respond `{ ok: true, ran: false, reason: 'debounced'
  }` and MUST NOT update the throttle timestamp or trigger a cycle.
- **stream-check-detached**: a call past the debounce floor MUST trigger the
  cycle via `scheduler.runNowDetached()` — fire-and-forget, NOT awaited —
  in explicit contrast to `cron.ts`'s `POST /cron/refresh`, which awaits
  `scheduler.runNow()`; this is a documented inconsistency between the two
  "trigger a cycle now" routes, not a shared contract.
- **stream-check-test-reset-hook**: `resetCheckThrottle()` MUST be exported
  as a test-only hook to clear the process-global debounce map between test
  cases.

### telemetry.ts

- **telemetry-injectable-fetchers**: `telemetryRoutes` MUST accept optional
  `deps.errorsFetcher`/`deps.analyticsFetcher`, defaulting to
  `buildErrorsFetcher`/`buildAnalyticsFetcher` built from `config` when not
  supplied, so tests can substitute fetchers without varying global state.
- **telemetry-last-good-fallback**: a failed poll of one provider MUST serve
  that stream's last successfully-polled value (or an empty list on a cold
  start with no prior success) rather than blanking it, and MUST NOT affect
  the other stream's value.
- **telemetry-single-flight-cache**: `GET /telemetry` MUST share a
  `CACHE_TTL_MS` (30,000 ms) single-flight cache across concurrent callers;
  `?fresh=1` MUST bypass a cached-but-not-in-flight result but MUST still
  join an already-in-flight build rather than starting a second one.
- **telemetry-no-store**: `GET /telemetry`'s response MUST carry
  `Cache-Control: no-store`.
- **telemetry-db-backed-endpoints**: `GET /errors` and `GET /analytics` MUST
  read from `storage.telemetry.errors.load()` / `storage.telemetry.analytics
  .load()` (SQLite-backed, not a live provider poll) and MUST carry
  `Cache-Control: public, max-age=30`.
- **telemetry-analytics-latest-reduction**: `GET /analytics` MUST reduce the
  stored rows to the latest value per `(metric, window, scope)` triple before
  responding.
- **telemetry-peer-token-excluded**: this file's routes MUST NOT accept
  `PEER_TOKEN` as a valid credential — peers exchange health snapshots
  (`/snapshot`), not telemetry, and this file is explicitly excluded from
  that exchange.

### tokens.ts — API token management

- **tokens-mint-requires-session-admin**: `POST /tokens` MUST require both
  `requireAdmin` AND a session `user` (`c.get('user')`) — `requireAdmin`
  alone also admits an admin bearer token and, under AUTH_DISABLED, an
  anonymous admin, but neither of those has an honest `created_by`, so both
  MUST respond 403 here even though `requireAdmin` would otherwise pass
  them.
- **tokens-mint-raw-once**: the raw token value MUST be returned exactly once,
  in the create response, with `Cache-Control: no-store`; it MUST NOT be
  retrievable from `GET /tokens` afterward.
- **tokens-list-no-store**: `GET /tokens` MUST carry `Cache-Control:
  no-store`.
- **tokens-delete-self-or-admin**: `DELETE /tokens/:id` MUST NOT be gated by
  the `requireAdmin` middleware; it MUST instead allow the call when the
  caller's tier is `'admin'` OR the caller's own token id equals the target
  id, and MUST respond 403 otherwise — a token MUST be able to revoke
  itself regardless of its own role.
- **tokens-delete-not-found**: revoking an id with no matching token MUST
  respond 404; a successful revoke MUST respond 204 with no body.

### users.ts — user administration

- **users-blanket-admin-gate**: every route MUST require admin via
  `app.use('*', requireAdmin)`.
- **users-role-body-validation**: `PATCH /users/:id`'s body MUST validate
  against `roleBody` (`role` in `pending`/`viewer`/`admin`); invalid JSON
  MUST respond 400 `'Invalid JSON'` and a role outside the enum MUST respond
  400 `'Invalid role'`.
- **users-last-admin-guard-atomic**: role changes MUST go through
  `setUserRoleGuarded`, whose guard is inside the write statement itself
  (not a preceding read) specifically to prevent two concurrent demotes of
  two different admins from both succeeding and leaving zero admins;
  `undefined` MUST map to 404, `'blocked'` MUST map to 409 `'Cannot demote
  the last admin'`.
- **users-delete-last-admin-guard-atomic**: `DELETE /users/:id` MUST use the
  same atomic-guard pattern via `deleteUserGuarded`; `false` MUST map to 404,
  `'blocked'` MUST map to 409 `'Cannot delete the last admin'`.
- **users-post-seam-mounting**: this sub-app is documented as mounted after
  the `requireAuth` seam and, within these files, after the device-approval
  trio in `device.ts`.

