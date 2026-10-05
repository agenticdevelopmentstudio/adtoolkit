
- **Data collected**: `users` stores an email, an optional bcrypt password
  hash, an optional external-identity id, and a display name (identity
  data); `sessions`/`apiTokens`/`deviceAuthorizations` store only the
  sha256 hash of a session token, API bearer, device code, and user code —
  never the raw secret at rest — with `deviceAuthorizations.tokenRaw` as
  the one documented, time-boxed exception (held only between approval and
  the single successful poll, then the row is deleted by code external to
  this recipe). `errors` and `analyticsMetrics` store polled, aggregate
  summaries (issue titles/culprits, pageview/visitor counts), not raw
  end-user request data.
- **Storage**: everything in this recipe's scope is persisted in the same
  embedded database file (or remote database) the connection-opening
  operation connects to. No table writes to a second store.
- **Transmission**: this storage layer performs no network calls of its
  own for an embedded-file connection; a remote connection's transport
  security is the underlying driver's responsibility, external to this
  recipe. The auth token is passed to that driver unchanged, never logged
  or persisted here.
- **Retention**: `healthChecks`, `metricsHourly`, `issues`,
  `analyticsMetrics`, and `deployments` are pruned/aged out by callers
  external to this recipe; several of the schema's own secondary indexes
  (`idx_health_checked`, `idx_metrics_hour`, `idx_issue_opened`,
  `idx_analytics_captured`, `idx_deploy_inflight`) exist specifically to
  make that external age-based pruning cheap. `deviceAuthorizations` rows
  are opportunistically reaped on a time-to-live (`expires_at`) — also
  external to this recipe. This storage layer itself deletes no row.

