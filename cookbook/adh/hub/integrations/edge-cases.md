
- **Null and empty input — path identifiers**: ecosystem id / provider id / config id / connection id
  are typed `string` and are not checked for emptiness client-side; an empty value is still
  percent-encoded (to the empty string) and sent, producing a request the backend answers with its own
  `404`/`400` — a non-empty identifier is a caller precondition, per the module's own top-of-file
  comment naming the ecosystem id as something "the caller must manage."
- **Null and empty input — `state`**: decoding OAuth state claims MUST return `null` for the empty
  string (no `.` present, per decode-state-claims-grammar) rather than throw.
- **Null and empty input — creating a link token's optional body**: an omitted body argument MUST be
  sent as `{}`, per create-link-token-request-shape; there is no distinct "send nothing" path.
- **Boundary values — OAuth state freshness**: the widened window's both edges are inclusive per
  state-freshness-window; one millisecond outside either edge MUST flip the result, as vectors 039–041
  show.
- **Boundary values — `state` grammar**: a `.` at position `0` or at the last character position are
  both rejected by decode-state-claims-grammar; a `.` anywhere strictly between the first and last
  character of a non-empty prefix and a non-empty suffix is the only accepted shape.
- **Concurrent access — module state**: the client holds no shared mutable state between calls (per
  stateless-module), so there is nothing for two concurrent calls to race on within this module itself.
- **Concurrent access — repeat connect calls**: both calls are sent; see connect-repeat-call-ordering
  below.
- **Concurrent access — repeat rotate-webhook-secret calls**: calling rotate-webhook-secret twice in
  succession MUST NOT be treated as idempotent — each call mints a distinct new secret and invalidates
  whatever secret the config held immediately before, by design
  (rotate-webhook-secret-is-destructive); this is the opposite of adopt-installations's documented
  safe-to-repeat behavior.
- **Error states — malformed test request vs. refused credential**: a malformed test request (unknown
  provider, undeclared field, non-testable provider) MUST throw, while a syntactically valid request
  the provider simply refuses MUST resolve with `ok: false` (test-result-ok-false-is-not-an-error) —
  these are two distinct failure shapes a caller must not conflate.
- **Error states — sync with no worker**: sync-no-worker-throws-503 is the one documented,
  provider-scoped status code this client's own comments call out by number; every other non-2xx
  status is handled only generically, via the thrown error's status/code.
- **Offline or disconnected state**: no operation in this client catches a network-level request
  rejection or retries beyond the single inherited `401` refresh-and-retry waterfall
  (session-refresh-waterfall); a connectivity loss mid-call propagates as an unhandled promise
  rejection out of this client to the caller, with no queuing or offline-specific handling anywhere in
  this file.
- **No timeout**: no operation in this file sets a deadline or passes a cancellation signal; a
  reachable-but-unresponsive backend leaves the call pending until the underlying request
  implementation's own limit, if any.
- **No cancellation**: no operation accepts a cancellation-signal parameter, so a caller cannot cancel
  an in-flight request through this module.
- **Building the OAuth callback URL outside a browser**: calling it where there is no browser page
  context (e.g. during server-side rendering) MUST throw whatever error accessing the page's location
  produces in that environment — a documented, client-only precondition
  (oauth-callback-url-is-origin-relative), not a gap this client guards against.
- **connect-repeat-call-ordering**: each connect call issues exactly one `POST /integrations/connect`
  with no idempotency key and no client-side de-duplication; two calls for the same provider id /
  service type / ecosystem id / external account — concurrent, or one retried after a dropped response
  — both reach the backend, which alone decides whether the second is an upsert, a conflict, or a
  second connection. Unlike adopt-installations, no comment documents a repeat connect as safe.

