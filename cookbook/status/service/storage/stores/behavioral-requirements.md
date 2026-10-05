
### Composition (index.ts)

- **storage-composition**: `createLibsqlStorage(db, conn?)` MUST return a
  `Storage` object with exactly these 13 keys, each built by calling the
  matching factory once: `config`, `auth`, `tokens`, `health`, `deploy`,
  `issues`, `observations`, `maintenance`, `board`, `history`, `device`,
  `peers`, `telemetry`.
- **connection-descriptor-scoping**: the optional `conn` (a
  `LibsqlConnection`) MUST be passed only to `createMaintenanceStore(db,
  conn)`; no other factory receives it. Omitting `conn` MUST still produce a
  complete `Storage` object — `createMaintenanceStore` treats a missing
  `conn` as "storage was built without a connection descriptor" (see
  `no-conn-degrades-maintenance` below), not as a construction error.

### Auth (auth-store.ts)

- **user-lookup**: `findUserByEmail`, `findUserByGithubId`, and
  `getUserById` MUST each return `undefined` (never throw, never a
  sentinel row) when no matching `users` row exists, and MUST return a
  `UserRecord` (including its stored password hash) when one does.
- **create-user-defaults**: `createUser` MUST insert a new `users` row and
  return the created `UserRecord`; a duplicate email or GitHub id MUST
  reject with the underlying unique-constraint violation rather than being
  pre-checked and swallowed.
- **role-listing-shape**: `listUsers` MUST return `AuthUser[]` (the
  password-hash-free, role-carrying projection), never the raw
  `UserRecord[]`.
- **last-admin-guard-update**: `setUserRoleGuarded(id, role)` MUST perform
  the role change and the "is this the last admin" check as one atomic
  UPDATE whose WHERE clause is `(role != 'admin' OR :role = 'admin' OR
  (select count(*) from users where role = 'admin') > 1)`, and MUST return
  the literal string `"blocked"` (not a thrown error, not `undefined`) when
  that WHERE clause excludes every row because the target is the sole
  remaining admin being demoted.
- **last-admin-guard-delete**: `deleteUserGuarded(id)` MUST apply the same
  atomic last-admin predicate to its DELETE, returning `"blocked"` when the
  target is the sole remaining admin, `true` when a row was deleted, and
  `false` when no row matched the id at all (a third, distinguishable
  outcome from `"blocked"`).
- **admin-count**: `countAdmins` MUST return the current count of `users`
  rows with `role = 'admin'` as a plain `number`.
- **session-lifecycle**: `createSession(userId, ttlMs = SESSION_TTL_MS)`
  MUST generate a fresh random token, persist only `tokenHash` (never the
  raw token) plus `expiresAt = now + ttlMs`, and return the one-time raw
  token to the caller; `resolveSession(token)` MUST hash the presented
  token, look up a non-expired `sessions` row by that hash, and return the
  owning user's `AuthUser` or `null` for a missing/expired/`undefined`
  token; `revokeSession(token)` MUST delete the matching row and MUST
  resolve without error when `token` is `undefined` or matches no row.

### API tokens (token-store.ts)

- **mint-hash-only**: `mintApiToken(input)` MUST generate a raw bearer
  token, persist only its `tokenHash` and a display-only `prefix` (the
  first `PREFIX_LEN` characters, `sts_`-namespaced via `TOKEN_PREFIX`), and
  return `{ meta, raw }` where `raw` is returned exactly once and is never
  written to storage in full.
- **validate-by-hash**: `validateApiToken(raw)` MUST hash the presented raw
  token and look up a non-revoked, non-expired `apiTokens` row by that
  hash, returning a `TokenPrincipal` on a match and `null` otherwise —
  including for an expired row, a revoked row, and a hash with no match.
- **token-listing-shape**: `listApiTokens` MUST return `ApiTokenMeta[]`
  (prefix and metadata only), never a raw or hashed token value.
- **revoke-vs-delete**: `revokeApiToken(id)` MUST mark the row revoked
  in place (kept for audit) and return `true` iff a row with that id
  existed; `deleteApiToken(id)` MUST remove the row entirely and return
  `true` iff a row with that id existed. Both MUST return `false`, not
  throw, for an id that matches no row.

### Device authorization (device-store.ts)

- **hash-only-persistence**: `create(input)` MUST persist
  `deviceCodeHash`/`userCodeHash` only — never the raw device or user code
  — alongside `status: "pending"` and an `expiresAt`.
  `findByDeviceCodeHash`/`findByUserCodeHash` MUST look up by the
  precomputed hash the caller supplies and return `null` for no match.
- **purge-expired**: `purgeExpired` MUST delete every `deviceAuthorizations`
  row whose `expiresAt` is in the past, and MUST resolve even when no row
  is expired.
- **approve-status-guard**: `approve(id, patch)` MUST update the row's
  status to `"approved"` (applying `patch`) only when its current status
  is `"pending"`, and MUST return `false` — not throw — when the row is
  missing or already in any other status, so a code that is polled,
  approved, and re-approved cannot silently re-run the approval side
  effects.
- **deny-status-guard**: `deny(id)` MUST apply the same "only from
  `pending`" guard as `approve`, setting status to `"denied"` and
  returning `false` for a non-`pending` or missing row.
- **single-use-consume**: `consumeApproved(id)` MUST atomically read and
  clear the row's one-time `tokenRaw`/`tokenId` in a single
  delete-returning statement scoped to `status = 'approved'`, returning
  `{ tokenRaw, tokenId }` exactly once for a given approved grant and
  `null` on every subsequent call for the same id (whether because it was
  already consumed or never approved) — this is the source's documented
  single-use, TOCTOU-safe consumption path, not a read-then-delete.
- **mark-polled**: `markPolled(id)` MUST update the row's last-polled
  timestamp and MUST resolve without error for a missing id (a poll racing
  a delete is not a fault).
- **role-and-expiry-lookup**: `tokenRoleAndExpiry(tokenId)` MUST return
  `{ role, expiresAt }` for a minted token id or `null` when the id is
  unknown.

### Health checks (health-store.ts)

- **latest-checks-batch**: `latestChecks(slugs)` MUST return one
  `LatestCheckRow` per slug in `slugs` that has at least one recorded
  check, using the single query `latestCheckBySlugSql(slugs)` — never one
  query per slug.
- **bad-run-onsets**: `badRunOnsets(slugs)` MUST return, per slug, the
  timestamp at which its current unbroken run of failing checks began, or
  omit the slug when its latest check is passing.
- **record-checks-bulk**: `recordChecks(checks)` MUST insert every
  `HealthCheckInput` in `checks` as its own `health_checks` row (append,
  never upsert — history is the point) and MUST resolve as a no-op for an
  empty array without issuing a statement.
- **checks-summary**: `checksSummary` MUST return the total sample count
  and the distinct-service count across all recorded checks.
- **last-checked-at**: `lastCheckedAtMs` MUST return the most recent
  check's timestamp in epoch milliseconds, or `null` when no check has
  ever been recorded.

### History and rollups (history-store.ts)

- **newest-check-at**: `newestCheckAt` MUST return the most recent
  `health_checks.checkedAt` across all services, or `null` for an empty
  table.
- **checks-for-window**: `checksFor(slug, hours)` MUST return every
  `health_checks` row for `slug` within the trailing `hours`-hour window,
  ordered so the caller can read it as a timeline.
- **daily-counts**: `dailyCounts(slug, days)` MUST return one
  `DailyCountsRow` per calendar day in the trailing `days`-day window for
  `slug`, including days with zero checks (a sparse day is a fact, not an
  absent row).
- **response-buckets**: `responseBuckets(hours, buckets)` MUST divide the
  trailing `hours`-hour window into exactly `buckets` equal-width
  sub-windows and return one average-or-`null` response value per bucket,
  `null` for a bucket with no checks in it.

### Issues (issue-store.ts)

- **list-open**: `listOpen` MUST return every `issues` row not yet
  resolved, as `IssueRow[]`.
- **insert-issue**: `insertIssue(input)` MUST insert a new open issue from
  an `IssueInsert`; the schema's own `uniq_open_issue_per_target` unique
  index (external to this file) is what prevents two simultaneously-open
  issues for the same target — `insertIssue` itself performs no
  pre-check, relying on that constraint to reject a duplicate.
- **update-issue**: `updateIssue(id, patch)` MUST apply `patch`'s fields
  to the row with that id and MUST resolve without error if no row
  matches (an issue closed by a concurrent resolve is not a fault for the
  update to report).
- **resolve-with-reason**: `resolveIssue(id, reason)` MUST mark the issue
  resolved, recording `reason` as one of the literal values
  `"recovered"`, `"unmonitored"`, or `"duplicate"`.
- **bulk-resolve-unmonitored**: `resolveUnmonitoredTargets(targets)` MUST
  resolve every currently-open issue whose target is in `targets` with
  reason `"unmonitored"`, and MUST resolve as a no-op for an empty
  `targets` array without issuing a statement whose `IN ()` would be
  invalid SQLite syntax.

### Platform observations (observation-store.ts)

- **streak-debounced-recording**: `recordObservations(observations)` MUST,
  per `PlatformObservationInput`, read the row's current
  `consecutiveFailures`, compute the next streak and "bad" verdict via
  `nextPlatformStreak(prevStreak, failing)` (imported from
  `monitor/issue-sources.ts`; a single passing poll resets the streak to
  `0` immediately, while a `bad` verdict requires the failure streak to
  reach the threshold), and upsert `platformHealthState` with the computed
  `consecutiveFailures`/`reachable`. The source comment states this
  function is the ONLY writer of `consecutiveFailures` in the codebase —
  a precondition on the wider system's call discipline, not a rule this
  file enforces on its own callers.
- **vercel-staleness-upsert**: `recordVercelProdStates(states)` MUST
  upsert one `platformHealthState`-adjacent row per state in `states` on
  conflict, then MUST delete every previously-stored row for a platform
  not present in the new `states` list for that call, so a project that
  stops being reported as a Vercel prod target stops being tracked as one.
- **tolerate-unmigrated-table**: any read that hits a
  not-yet-migrated table MUST distinguish a driver error whose message
  matches `/no such table|does not exist|not found/i` (tolerated, treated
  as "no data yet") from every other driver error (rethrown) — this is the
  same pattern `config-store.ts`'s `listIgnoredProjects` uses, not unique
  to this file.

### Owned-project predicate (owned-deploys.ts)

- **owned-scope-predicate**: `ownedDeploysWhere(projects)` MUST return a
  Drizzle `SQL` fragment (or `undefined`) that scopes a `deployments` query
  to exactly the platform/project-name pairs named in an `OwnedProjects`
  set, and MUST return `undefined` — not a fragment that matches nothing
  or everything — when `projects` denotes no scoping at all, so a caller
  can splice the result into a WHERE clause unconditionally.
- **shared-not-duplicated**: `deploy-store.ts`'s `listRecentOwned` and
  `board-store.ts`'s `readDeployEvents`/`readDeployActivityPage` MUST each
  call this one exported function rather than re-deriving their own
  platform/project predicate, so the definition of "owned" cannot drift
  between the deploy log and the board.

### Peer fleet-view (peer-store.ts)

- **active-peer-listing**: `listActive` MUST return every `peers` row
  currently marked active, as `PeerRow[]`, with no redaction applied in
  this file — `redactPeer()` (defined in `ports.ts`, external to this
  file) is the documented redaction step, applied by a caller outside
  this store before a peer row reaches an untrusted audience.
- **snapshot-upsert**: `upsertSnapshot(row)` MUST insert a new
  `peerSnapshots` row or overwrite the existing one for that peer on
  conflict, so only the latest snapshot per peer is ever retained by this
  method.
- **snapshot-listing**: `listSnapshots` MUST return the current
  one-row-per-peer snapshot set as `PeerSnapshotRow[]`.

### Deployments (deploy-store.ts)

- **chunked-upsert**: `upsertDeployments(deploys, opts?)` MUST upsert in
  batches no larger than `UPSERT_CHUNK_PROJECTS` deployments per
  statement, to stay under SQLite's bound parameter-count limit.
- **invalid-createdat-dropped-not-failed**: a deployment in the input
  array whose `createdAt` fails validation MUST be dropped from that
  chunk's statement (logged via `console.error` with the message
  `` `[sync] deploy ${d.id} has an invalid createdAt — dropping it
  (fetcher should have caught this)` ``) rather than failing the whole
  batch — one bad row from an upstream fetcher MUST NOT block every valid
  row alongside it from being stored.
- **created-at-minimum**: on conflict, `createdAt` MUST be updated to
  `min(excluded.created_at, created_at)` — never overwritten upward —
  because a webhook event's timestamp is emission time, always at or after
  true creation time.
- **fetched-at-advances**: on conflict, `fetchedAt` MUST be updated to the
  time of this upsert (advances monotonically), independent of
  `createdAt`'s minimum rule.
- **webhook-poll-ordering-guard**: on conflict, columns governed by
  `webhookKeepsStoredSql`/`columnOverwritableSql` (imported from
  `monitor/deploy-status.ts`) MUST NOT let a stale webhook event regress a
  column past either (a) an already-settled verdict or (b) a phase later
  in `IN_FLIGHT_BUILD_ORDER` than the one the event reports, while a poll
  (`opts.source` unset or not `"webhook"`) MUST be allowed to move the
  same column backward to in-flight, because a poll's by-id read is
  current truth rather than a possibly-reordered event.
- **project-name-refreshed**: on conflict, `projectName` MUST be
  overwritten unconditionally (never frozen at insert), so a project
  rename upstream is reflected rather than leaving the row keyed to a
  stale name in every subsequent `groupBy(platform, projectName,
  environment)` read.
- **provider-project-id-non-erasing**: on conflict,
  `providerProjectId` MUST be updated via COALESCE-style
  keep-if-sparser-source logic — a sparser source (for example a webhook
  payload with no id) MUST NOT erase an already-stored value; a richer
  source with a new id MUST overwrite it.
- **learn-project-ids-chunked**: `learnProjectIds(...)` MUST also chunk
  its writes and MUST only ever narrow `providerProjectId` from unset to
  set, never overwrite an already-set value with a different one.
- **prune-by-age**: `pruneOlderThanDays(days)` MUST delete every
  `deployments` row older than `days` days.
- **in-flight-expiry**: `expireStaleInFlight(olderThanMs)` MUST move every
  deployment whose build/deploy phase is in-flight (per `isInFlight` from
  `monitor/deploy-status.ts`) and whose last update predates
  `olderThanMs` to a terminal "gone/unknown" phase via
  `collapseInFlightBuildSql`/`collapseInFlightDeploySql`, and MUST return
  the count of rows it changed.
- **mark-gone-and-phases**: `markDeployGone(id)` and
  `markDeployPhases(id, phases)` MUST each update exactly the row matching
  `id`, resolving without error if no row matches.
- **error-text-set-once-elsewhere**: `setErrorText(id, text)` MUST set the
  stored error text for a deployment; `listFailedWithoutError(input)` MUST
  return only failed deployments whose error text is still unset, so a
  caller can target enrichment at exactly the rows that need it.
- **project-meta-crud**: `upsertProjectMeta`, `listProjectMetaNames`,
  `listProjectMeta`, and `deleteProjectMeta` MUST manage the
  `deploy_project_meta` table keyed by `(platform, name)`;
  `deleteProjectMeta(platform, names)` MUST chunk its deletion no larger
  than `DELETE_CHUNK_NAMES` names per statement and MUST no-op for an
  empty `names` array rather than issue an invalid empty `IN ()`.
- **owned-scoped-listing**: `listRecentOwned(owned, limit)` MUST scope its
  query with `ownedDeploysWhere(owned)` and MUST return at most `limit`
  rows, most-recent first.
- **find-by-id**: `findById(id)` MUST return the full `DeployLogRow` for
  `id` or `null` when no such deployment exists.

### Board read model (board-store.ts)

- **shared-lifecycle-predicates**: every read that classifies a deployment
  as concluded, in-flight, having an outcome, or lacking a lifecycle MUST
  use the module's shared `CONCLUDED`/`IN_FLIGHT`/`HAS_OUTCOME`/
  `NO_LIFECYCLE` SQL predicates rather than re-deriving equivalent
  conditions per method, so the board's definition of each state cannot
  drift between `readRoster`, `readDeployOutcomeCandidates`, and the
  paginated readers.
- **read-only-surface**: `readRoster`, `readDeployOutcomeCandidates`,
  `readDeployEvents`, `readIssueEvents`, `readOpenIssueTargets`,
  `readPlatformFacts`, `readStaleProdFacts`, and `readErrorFacts` MUST
  each be a pure read with no side effect on the underlying tables — this
  store never writes.
- **owned-scoped-deploy-events**: `readDeployEvents(sinceMs, owned)` MUST
  scope with `ownedDeploysWhere(owned)` and MUST return only events at or
  after `sinceMs`.
- **tie-safe-pagination**: `readDeployActivityPage(cursor, owned)`,
  `readIssueOpenedPage(cursor, targets)`, and `readIssueResolvedPage(cursor,
  targets)` MUST each accept a `PageCursor` and return a `SourcePage<T>`
  whose `beforePredicate` breaks ties on a secondary key (not timestamp
  alone), so two rows with the same timestamp are never silently dropped
  or duplicated across a page boundary.

### Monitoring configuration (config-store.ts)

- **group-crud**: `listSiteGroups`, `createGroup`, `updateGroup`, and
  `deleteGroup` MUST manage `site_groups`; `deleteGroup` MUST also delete
  every `monitored_sites`/`monitored_endpoints` row scoped under that
  group and every `health_checks`/`issues` row for those endpoints in the
  same call, so deleting a group MUST NOT leave orphaned history or open
  issues behind it.
- **site-crud-cascade**: `createSite`, `updateSite`, and `deleteSite`
  parallel the group operations one level down; `deleteSite` MUST cascade
  the same history/issue purge for the endpoints under that site.
- **endpoint-crud-cascade**: `createEndpoint`, `updateEndpoint`, and
  `deleteEndpoint` MUST manage `monitored_endpoints`; `deleteEndpoint`
  MUST purge that endpoint's `health_checks` and resolve its open
  `issues` via `purgeEndpointHistory`.
- **atomic-two-statement-write**: any create/update path here that must
  write two related statements as one unit (for example inserting a row
  and its default child rows) MUST use `db.batch(...)`, never
  `db.transaction(...)` — the source comment documents that this driver's
  `transaction()` hands off the connection and nulls its own handle, so
  against a `:memory:` database the next statement after a
  `db.transaction()` call lazily opens a brand-new, empty in-memory
  database instead of continuing the one just written to.
- **active-endpoints-listing**: `listActiveEndpoints` MUST return every
  endpoint eligible to be polled right now, as `ConfiguredEndpoint[]`,
  joined up through its site and group.
- **toctou-safe-retire**: `retireEndpoint(id)` MUST perform its
  conditional delete as a single statement whose WHERE clause includes a
  `NOT EXISTS` subquery re-evaluated at delete time (never a separate
  read-then-delete), so a row that became newly ineligible between a
  caller's check and this call is still handled correctly rather than
  raced.
- **fresh-subquery-orphan-reconcile**: `reconcileOrphanedEndpoints` MUST
  recompute its orphan set as a subquery evaluated at delete time (not
  from a previously-read id list), and MUST log via `console.error` with
  the prefix `[config] orphan endpoint/site reconcile failed:` and return
  a partial `{ endpoints, sites, prunedEndpointIds }` result reflecting
  whatever portion of the two-step delete actually completed, rather than
  letting a failure partway through the reconcile propagate uncaught.
- **integration-crud**: `listIntegrations`, `createIntegration`, and
  `updateIntegration` MUST manage the `integrations` table.
- **delete-integration-one-directional**: `deleteIntegration(id)` MUST
  delete the integration and MUST set
  `platformHealthState.configured = false` for its platform as part of
  the same statement, but MUST NEVER itself set `configured = true` — the
  source comment states the monitor cycle is the only thing allowed to
  make that determination, and this method can only ever weaken it toward
  `false`, one-directionally.
- **ignored-projects-tolerant-read**: `listIgnoredProjects` MUST tolerate
  a not-yet-migrated `ignored_projects` table by treating a driver error
  matching `/no such table|does not exist|not found/i` as "no ignored
  projects yet" and rethrowing every other error unchanged.
- **ignored-projects-write**: `addIgnoredProject`,
  `addIgnoredProjects` (chunked bulk form), and `removeIgnoredProject`
  MUST manage the `ignored_projects` table by `(platform, projectName)`.
- **peer-crud**: `listPeers`, `createPeer`, `updatePeer`, and `deletePeer`
  MUST manage the `peers` table used by config-side peer administration
  (distinct from `peer-store.ts`'s fleet-view snapshot reads).

### Maintenance (maintenance-store.ts)

- **rollup-metrics**: `rollupMetrics(serviceSlugs)` MUST recompute and
  upsert `metrics_hourly` buckets for every hour touched by
  `health_checks` rows for `serviceSlugs`, via the exported
  `rollupMetricsSql(serviceSlugs)` fragment.
- **budgeted-chunked-prune**: the retention prune inside `runMaintenance`
  MUST delete in batches no larger than `PRUNE_CHUNK_ROWS` rows per
  statement and MUST stop once it has deleted `PRUNE_MAX_ROWS_PER_RUN`
  rows in a single call, deferring any remaining backlog to the next
  scheduled run rather than running one unbounded delete.
- **fail-soft-checkpoint**: `runMaintenance`'s WAL-checkpoint step MUST
  catch any error from `checkpointWal` and log it via `console.error` with
  the message `` `[maintenance] wal checkpoint failed: ${message}` ``
  rather than letting a checkpoint failure abort the rest of the
  maintenance cycle.
- **no-conn-degrades-maintenance**: when `createMaintenanceStore` was
  built without a `conn`, the WAL-checkpoint and DB-snapshot steps MUST
  be skipped rather than throw; the first time either step is skipped,
  `warnNoConn(step)` MUST log exactly once per store instance via
  `console.warn` with the message `` `[maintenance] ${step} skipped:
  storage was built without a connection descriptor
  (createLibsqlStorage(db, conn)) — WAL checkpoint and DB snapshots are
  disabled` `` — every later skip in the same store instance MUST NOT
  log again.
- **snapshot-fail-soft**: `snapshotIfDue(opts?)` MUST catch any error
  from the VACUUM-INTO snapshot attempt, log it via `console.error` with
  the message `` `[snapshot] failed: ${message}` ``, and resolve `{
  created: false }` rather than reject — a failing backup MUST NOT fail
  the maintenance cycle it rides along with.
- **snapshot-success-logged**: on a successful snapshot,
  `snapshotIfDue` MUST log via `console.log` with the message
  `` `[snapshot] wrote ${finalPath}` `` and resolve `{ created: true,
  path: finalPath }`.

### Telemetry (telemetry-store.ts)

- **errors-reconcile-not-append**: `errorsStore.save(items, opts?)` MUST
  upsert every item in `items` by `issueKey` and MUST then resolve every
  currently-unresolved row NOT present in `items` to `resolved = true`,
  UNLESS `opts.complete === false`, in which case the sweep MUST be
  skipped entirely for that call — an item present in `items` but not
  seen on a prior call MUST also be reopened (`resolved` reset to
  `false`) via the upsert's own `excluded.resolved` conflict clause.
- **empty-poll-resolves-all**: an empty `items` array with
  `opts.complete !== false` MUST resolve every still-open row, and MUST
  do so via a branch that does not compile to `NOT IN ()` (invalid SQLite
  syntax for an empty exclusion list) — this is the case
  `notInArray` cannot express directly and the store MUST route around
  it explicitly.
- **fetched-at-not-restamped-on-sweep**: a row resolved by the sweep
  (because it was absent from the poll) MUST NOT have its `fetchedAt`
  updated — `fetchedAt` records when a row was last actually seen, and a
  swept row was, by definition, not seen this poll.
- **truncated-poll-logged-not-swept**: when the upstream poll itself was
  truncated (a full page with no confirmation the answer is complete),
  `save` MUST upsert whatever it saw and MUST skip the sweep, logging via
  `console.warn` with the message `` `[telemetry] GlitchTip returned a
  full page (${items.length}); the unresolved set is truncated, so no
  rows were swept this poll` `` — sweeping a partial page would resolve
  everything past its edge and cause a flap between open and resolved on
  every subsequent poll for a project whose issue count straddles the
  page boundary.
- **project-refreshed-on-conflict**: on conflict, `project` MUST be
  overwritten (never frozen at first insert) — `project` is the field the
  board mints its issue-ledger key from, so a stale value would derive a
  target no current fact mentions.
- **analytics-append-only**: `analyticsStore.save(items)` MUST plain
  insert every item with no conflict handling — analytics rows are
  point-in-time samples, never upserted or reconciled the way errors are.
- **errors-and-analytics-load**: `errorsStore.load()` MUST return only
  currently-unresolved rows; `analyticsStore.load()` MUST return every
  stored sample.

