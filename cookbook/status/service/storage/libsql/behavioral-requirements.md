
### Connection

- **schema-type-alias**: the exported schema type MUST equal the full schema
  module's own namespace type.
- **db-type-alias**: the exported connection type MUST equal the underlying
  database-connection type, parameterized by the schema type.
- **connection-url-required**: the connection-opening operation MUST throw
  an error with message `"libsql connection url is empty (e.g. file:./status.db)"`
  when the connection URL is empty (falsy).
- **connection-construction**: the connection-opening operation MUST
  construct and return a connection object using the given URL and auth
  token for a non-empty URL, passing the auth token through unchanged
  (including when absent).
- **connection-per-caller**: the connection-opening operation MUST create a
  fresh connection on every call; the API server and the monitor worker each
  hold their own connection to the same file, and neither the connection
  layer nor the schema provides any cross-connection locking beyond the
  pragmas the concurrency-tuning operation applies.
- **embedded-file-detection**: the embedded-file check MUST return `true`
  if and only if the connection URL starts with the literal prefix
  `"file:"`, and MUST return `false` for every other value, including an
  `https://` or a remote-database URL.

### Concurrency Tuning

- **tune-noop-for-remote**: the concurrency-tuning operation MUST resolve
  without executing any PRAGMA when the connection is not an embedded file.
- **tune-wal-mode**: for an embedded-file connection, the concurrency-tuning
  operation MUST execute `PRAGMA journal_mode = WAL`.
- **tune-busy-timeout**: for an embedded-file connection, the
  concurrency-tuning operation MUST execute `PRAGMA busy_timeout = 5000`
  (5000 milliseconds).
- **tune-synchronous-normal**: for an embedded-file connection, the
  concurrency-tuning operation MUST execute `PRAGMA synchronous = NORMAL`,
  after the write-ahead-log and busy-timeout pragmas, in that order.
- **tune-idempotent-reapply**: re-invoking the concurrency-tuning operation
  against an already-tuned embedded-file connection MUST be safe to call
  again — write-ahead-log mode is a persistent property of the database
  file, so re-applying it is a no-op.

### Checkpoint

- **checkpoint-noop-for-remote**: the checkpoint operation MUST resolve
  `null` without executing any PRAGMA when the connection is not an
  embedded file.
- **checkpoint-truncate**: for an embedded-file connection, the checkpoint
  operation MUST execute `PRAGMA wal_checkpoint(TRUNCATE)` — the only
  checkpoint mode that returns the write-ahead log's disk footprint to the
  volume (a passive-mode auto-checkpoint resets the log without truncating
  it).
- **checkpoint-result-shape**: the checkpoint operation MUST resolve a
  result shaped as `{ busy, frames }`, where `busy` is `true` exactly when
  the checkpoint query's first result row's `busy` field equals `1`, and
  `frames` is the numeric value of that row's `checkpointed` field,
  defaulting to `0` when the row or field is absent.
- **checkpoint-fail-soft**: the checkpoint operation MUST NOT throw when
  the checkpoint reports busy; a busy checkpoint MUST resolve
  `{ busy: true, frames }` — this is fail-soft by design: the database is
  left untouched and the next maintenance pass tries again.

### Package Root and Migrations

- **package-root-resolution**: the package-root resolution MUST locate this
  package's own installed root directory via the host runtime's own
  module-resolution mechanism, so it is correct whether the caller runs
  from source, from a built distribution, or from a host's vendored copy.
- **migrations-folder-constant**: the exported migrations-folder constant
  MUST equal the package root's `src/libsql/migrations` subdirectory.
- **migrate-default-folder**: the migration operation MUST use the
  migrations-folder constant as the migrations folder when the caller
  passes no explicit migrations-folder argument.
- **migrate-applies-pending**: the migration operation MUST apply, via the
  schema's own migration mechanism, every migration under the migrations
  folder not yet recorded in the migration-history table, in journal order.
- **migrate-idempotent**: the migration operation MUST be safe to call
  repeatedly against the same database — a second or third call after all
  migrations are applied MUST resolve without error and MUST leave the
  schema unchanged and queryable.
- **migrations-immutable**: every shipped migration file under the
  migrations folder MUST remain byte-for-byte unchanged once recorded in
  the migration journal — migrations are applied in production already and
  are immutable: never edit one, only add. A new migration MUST be added as
  a new file.

### Schema — health checks and metric rollups

- **health-check-row-shape**: `healthChecks` MUST persist one row per probe
  with `serviceSlug`, `status` (`'healthy' | 'degraded' | 'down'`), nullable
  `responseTimeMs`/`statusCode`/`error`, a `dnsOk` boolean defaulting
  `true`, and a `checkedAt` timestamp defaulting to the database's own
  current-time function.
- **health-check-indexing**: `healthChecks` MUST be indexed on
  `(serviceSlug, checkedAt)` for per-service lookups, and independently on
  `checkedAt` alone — the age-only retention prune (`where checked_at <
  cutoff`) cannot be served by the composite index, whose leading column is
  `serviceSlug`.
- **metrics-hourly-uniqueness**: `metricsHourly` MUST enforce at most one
  row per `(serviceSlug, hour)` pair via `uniq_metrics_service_hour`, and
  MUST be independently indexed on `hour` alone for the same age-only
  retention-prune reason as `healthChecks`.

### Schema — deployments and issues

- **deployment-row-identity**: `deployments.id` MUST be the primary key and
  MUST hold the platform-prefixed id format (`vc_<uid>` for Vercel,
  `cf_<id>` for Cloudflare Pages, `ry_<id>` for Railway).
- **deployment-project-identity-fallback**: `deployments.providerProjectId`
  MUST be nullable; when `null`, identity for that row falls back to
  `projectName`.
- **deployment-legacy-status-column**: `deployments.status` MUST remain a
  nullable column, retained only so a rolling deploy does not break
  still-live old code while migrations auto-apply; current code MUST
  derive status from `buildPhase`/`deployPhase`, never from `status` — the
  column is vestigial and slated for removal once every environment is cut
  over.
- **deployment-phase-defaults**: `deployments.deployPhase` MUST default to
  `'none'`; `deployments.buildPhase` MUST be nullable with no default.
- **deployment-created-indexing**: `deployments` MUST be indexed on
  `createdAt` (`idx_deploy_created`).
- **deployment-inflight-index**: `deployments` MUST carry a partial index
  (`idx_deploy_inflight`) on `fetchedAt`, scoped to rows matching a shared
  in-flight-detection predicate used elsewhere in this backend, so both the
  reconcile candidate query and the expiry sweep seek a small index every
  tick instead of scanning the full retained deploy history — this is
  tied directly to a production incident where the equivalent unindexed
  scan on `health_checks` took the container down.
- **issue-uniqueness-open**: `issues` MUST enforce at most one open row per
  `target` via `uniq_open_issue_per_target`, a unique index scoped to
  `resolved_at is null`, so the database itself rejects a second
  concurrently-open issue for the same target.
- **issue-resolution-reason**: `issues.resolvedReason` MUST be nullable
  and, when set, MUST hold either `'recovered'` or `'unmonitored'`; only a
  `'recovered'` close is eligible to become an activity-feed entry.
- **issue-history-indexing**: `issues` MUST be indexed independently on
  `resolvedAt` (`idx_issue_resolved`), on `source` (`idx_issue_source`), and
  on `openedAt` (`idx_issue_opened`) — the last serving a 90-day paged
  activity-history read ordered by `openedAt`, for the same
  scan-grows-with-history reason as `idx_deploy_inflight`.

### Schema — monitoring configuration

- **site-group-uniqueness**: `siteGroups.slug` MUST be unique
  (`uniq_site_group_slug`); `retentionDays` MUST default to `14`.
- **monitored-site-uniqueness**: `monitoredSites` MUST enforce uniqueness
  of `(siteGroupId, slug)` via `uniq_site_group_site_slug`, and MUST
  declare a foreign key to `siteGroups.id` with cascading delete.
- **monitored-endpoint-fk**: `monitoredEndpoints.siteId` MUST declare a
  foreign key to `monitoredSites.id` with cascading delete, and MUST be
  indexed (`idx_endpoint_site`) for per-site lookup.
- **fk-cascade-not-enforced-over-http**: the cascading-delete declarations
  on `monitoredSites` and `monitoredEndpoints` MUST be understood as
  documentation of intent only — this storage layer's remote transport does
  not enforce foreign-key constraints over that transport, so deleting a
  group or a site (external to this recipe) cascades in application code,
  never by relying on the database to do it.
- **endpoint-check-defaults**: `monitoredEndpoints` MUST default `kind` to
  `'http'`, `expectedStatus` to `200`, `checkIntervalSeconds` to `60`,
  `dnsCheckA`/`dnsCheckAaaa`/`dnsCheckCname` to `true`, `isActive` to
  `true`, `monitorHttp` to `true`, `monitorDeploys` to `true`, and
  `ignoreProjectWarning` to `false`.
- **endpoint-per-signal-toggles**: `monitoredEndpoints.monitorHttp` and
  `monitoredEndpoints.monitorDeploys` MUST be independent of `isActive` and
  of each other — turning one signal off removes only that signal's
  problems from the board while the master switch and the other signal
  remain unaffected.
- **endpoint-deploy-project-id-write-once**: `monitoredEndpoints.deployProjectId`
  MUST be nullable, with `null` meaning not yet learned; once a value is
  learned it is never overwritten automatically, so an operator-entered
  value always wins. The schema itself declares no trigger or default
  enforcing this — it is a documented invariant of the column's meaning
  that the calling code (external to this recipe) is responsible for
  upholding, the same way fk-cascade-not-enforced-over-http is.
- **deploy-platform-tables-reexported**: `deployIntegrations`,
  `deployProjectMeta`, and `ignoredDeployProjects` MUST be re-exported from
  a shared deploy-platform package rather than declared locally, so every
  existing importer's schema-module path continues to resolve them.

### Schema — platform and peer state

- **platform-health-state-shape**: `platformHealthState` MUST key one row
  per `source` (platform identifier), tracking `consecutiveFailures`
  (default `0`), `configured` (default `true`), and `reachable` (default
  `true`); both boolean defaults are documented as deliberate, benign
  guesses about pre-existing rows, not facts.
- **vercel-prod-state-shape**: `vercelProdState` MUST key one row per
  `projectName`, with `stale` defaulting to `false`; the row is replaced
  wholesale on every complete read, never merged field-by-field.
- **peer-uniqueness**: `peers.baseUrl` MUST be unique
  (`uniq_peer_base_url`); `peers.token` MUST be nullable, with `null`
  meaning the peer's own reads are public (no bearer required).
- **peer-snapshot-fk**: `peerSnapshots.peerId` MUST be the primary key and
  MUST declare a foreign key to `peers.id` with cascading delete;
  `peerSnapshots.reachable` MUST default to `false`.

### Schema — errors and analytics

- **error-row-uniqueness**: `errors.issueKey` MUST be unique
  (`uniq_error_issue`) — one row per external issue id, upserted by callers
  external to this recipe; `errors` MUST be indexed on `lastSeen`
  (`idx_error_last_seen`); `count` and `userCount` MUST each default to
  `0`, and `resolved` MUST default to `false`.
- **analytics-metrics-indexing**: `analyticsMetrics` MUST be indexed on the
  composite `(metric, window, scope, capturedAt)`
  (`idx_analytics_metric_time`) for the dashboard's latest-value/trend
  reads, and independently on `capturedAt` alone
  (`idx_analytics_captured`) for the same age-only retention-prune reason
  as `healthChecks`; `scope` MUST default to `'all'`.

### Schema — authentication and tokens

- **user-uniqueness**: `users.email` and `users.githubId` MUST each be
  unique (`uniq_user_email`, `uniq_user_github`); `role` MUST default to
  `'pending'`; `passwordHash` and `githubId` MUST each be independently
  nullable, supporting OAuth-only and password-only accounts respectively.
- **session-token-hash-only**: `sessions` MUST persist only `tokenHash`
  (unique, `uniq_session_token`), never a raw session token — so a database
  leak cannot reconstruct live cookies; `sessions.userId` MUST declare a
  foreign key to `users.id` with cascading delete, and MUST be indexed
  (`idx_session_user`).
- **api-token-hash-only**: `apiTokens` MUST persist only `tokenHash`
  (unique, `uniq_api_token_hash`) plus a display-only `prefix` (the raw
  value's leading 12 characters), never the raw bearer value; `role` MUST
  be `'admin' | 'user'`; `kind` MUST default to `'minted'`; `createdBy`
  MUST declare a foreign key to `users.id` with cascading delete;
  revocation MUST be represented by setting `revokedAt`, never by deleting
  the row.
- **api-token-created-at-app-default**: `apiTokens.createdAt` and
  `deviceAuthorizations.createdAt` MUST be populated by application code at
  insert time (a computed default evaluated by the calling program) rather
  than by a database-level default — unlike every other timestamp column in
  this schema, which defaults via the database's own current-time function.
  A row inserted through raw SQL that bypasses the normal insert path would
  leave these two columns null-violating, since both are required with no
  database-level default.
- **device-auth-hash-only-except-raw**: `deviceAuthorizations` MUST persist
  only `deviceCodeHash` and `userCodeHash` (each unique, `uniq_device_code`
  and `uniq_user_code`), never the plaintext device or user code;
  `tokenRaw` MUST be the one column in this schema documented to briefly
  hold a plaintext secret, and only between approval and the single
  successful poll — the row is then deleted (single-use) by code external
  to this recipe, and `tokenRaw` is never selected in any list path.
- **device-auth-status**: `deviceAuthorizations.status` MUST default to
  `'pending'` and be one of `'pending' | 'approved' | 'denied'`; `tokenId`
  MUST declare a foreign key to `apiTokens.id` that nulls out on delete;
  `approvedBy` MUST declare a foreign key to `users.id` that nulls out on
  delete.
- **exported-row-types**: the schema MUST export public type aliases for a
  user row, a new-user insert shape, and a session row, each mechanically
  derived from the corresponding table's own column definitions, so the
  alias always matches the table exactly with no hand-maintained duplicate
  shape.

