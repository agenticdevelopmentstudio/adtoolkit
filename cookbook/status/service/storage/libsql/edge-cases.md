
- **Null and empty input**: an empty connection URL is rejected explicitly
  by connection-url-required, the one input validation this storage layer
  performs; every other "missing" value in the schema (a nullable column
  with no default — `providerProjectId`, `error`, `resolvedReason`,
  `deployProjectId`, `token`) is a first-class, documented `null`, not an
  unhandled gap.
- **Boundary values**: the checkpoint operation's `frames` count defaults
  to `0` when the checkpoint result row or its `checkpointed` field is
  absent (checkpoint-result-shape) — the fallback is a boundary case
  handled explicitly, not an unguarded read. `metricsHourly.hour` and
  `analyticsMetrics.capturedAt` are unix-second timestamps truncated to
  their aggregation boundary by callers external to this storage layer
  (the schema itself carries no truncation logic).
- **Concurrent access**: the entire concurrency-tuning half of this storage
  layer (tune-wal-mode, tune-busy-timeout, tune-synchronous-normal) exists
  because the API server and the monitor worker hold independent
  connections to the same embedded file. `uniq_open_issue_per_target` and
  `uniq_metrics_service_hour` are the schema's own concurrency guards — a
  losing concurrent insert is rejected by the database itself, not
  silently merged. The checkpoint operation's fail-soft `busy` result is
  the documented outcome when a checkpoint races a live reader.
- **Error states**: the connection-opening operation throws synchronously
  for the one input it validates (an empty URL); every unique-index and
  foreign-key violation in the schema (issue-uniqueness-open,
  metrics-hourly-uniqueness, peer-uniqueness, user-uniqueness,
  session-token-hash-only, api-token-hash-only,
  device-auth-hash-only-except-raw) surfaces as a rejected promise from the
  underlying database driver — nothing in this storage layer wraps or
  swallows a driver rejection anywhere.
- **Offline / disconnected state**: a remote connection going unreachable
  is not handled by this storage layer directly — the embedded-file check
  routes all tuning and checkpointing around remote connections
  specifically because a remote database manages its own journaling,
  durability, and storage. Reconnection, retry, and backoff for a remote
  connection are the responsibility of the underlying database driver,
  external to this storage layer.

