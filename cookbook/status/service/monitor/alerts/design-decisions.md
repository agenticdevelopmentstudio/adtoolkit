
- **Decision**: drain the queue (`queue.splice(0)`) before attempting the webhook POST, rather than after a successful response.
  **Rationale**: stated directly in the source comment on `flushAlerts` — delivery is "fail-soft (a down webhook endpoint is logged and the batch dropped — the open issue itself is durable in the DB either way)." Draining first means a slow or repeatedly-invoked flush never accumulates an ever-growing in-flight batch, at the deliberate cost that a failed POST permanently loses that specific batch instead of retrying it later; the tradeoff is acceptable because the underlying issue state lives durably in the database regardless of whether the notification about it was ever delivered.
  **Approved**: pending
- **Decision**: bound the queue at 100 entries and drop the OLDEST entry on overflow (`queue.shift()`), rather than dropping the newest or refusing to enqueue.
  **Rationale**: the source comment on `MAX_QUEUED` states the queue "only ever accumulates within one cycle (the cycle flushes), so hitting this means something is very wrong." Once something has already gone wrong enough to hit the bound, keeping the most recently queued (and therefore most current) transitions is more actionable to on-call than preserving the oldest history.
  **Approved**: pending
- **Decision**: give `resolved` and `retired` alerts narrower render templates than `opened` — `resolved` drops `state` and `detail` entirely; `retired` drops `state` but keeps `detail`.
  **Rationale**: not spelled out in a comment beyond the `kind` field's own distinction; recorded here as an observed, deliberate fact of `line()`'s three branches rather than an invented rationale — a recovery message needs no further explanation (the outage is simply over), while a retirement needs the removal reason (`detail`) to tell on-call why the monitor disappeared, but has no live `state` left to report since nothing is being monitored any more.
  **Approved**: pending
- **Decision**: keep `notifyIssueAlert` synchronous and side-effect-free beyond the in-memory push, deferring all I/O and the alerting on/off decision to the separately-invoked `flushAlerts`.
  **Rationale**: stated directly in the source comment on `notifyIssueAlert` — enqueuing is "cheap + sync — safe to call from the recorders' hot path, with no config in scope there," and gating on the URL is deliberately `flushAlerts`'s job so an unqueued alert while alerting is off would leave an earlier `opened` alert with no matching `resolved`/`retired` counterpart once alerting turns back on.
  **Approved**: pending
- **Decision**: provide `_resetAlerts` as a test-only escape hatch with no production equivalent.
  **Rationale**: the function's own doc comment calls it a "Test hook — drop queued alerts." Production code has no path that clears the queue other than a successful `flushAlerts` drain, which is consistent with the queue being expected to fully empty via `flushAlerts` every cycle rather than ever needing an out-of-band reset.
  **Approved**: pending

**Decision**: A non-2xx webhook response is not detected, logged or retried.
**Rationale**: It stands today because only the thrown-error path is handled. Closing it needs confirmation that checking the response status and logging a non-2xx the way the catch path logs a thrown error is the intended fix, rather than trusting receivers to accept well-formed payloads, and a test with a rejecting receiver.
**Approved**: pending

