
- **Null/empty input**: token extraction from `{}` (neither field present) —
  MUST throw (auth-client-011). Reading relayed central-login parameters
  from an empty query (no query at all) — MUST return nothing
  (auth-client-086). Parsing an inbound SSO fragment from `''` — MUST return
  nothing (auth-client-077). Taking the return-to value with nothing
  stashed — MUST return nothing.
- **Boundary/malformed values**: A stored token bundle that is not valid
  JSON — MUST be treated as absent, never thrown (auth-client-014). A `sub`
  claim that decodes to a non-string — MUST be treated as absent
  (`read-token-subject-derivation`). A base64url segment with stripped
  padding — MUST still decode (auth-client-022). A base64url segment with an
  invalid UTF-8 byte sequence — MUST decode to nothing, never substitute
  U+FFFD (auth-client-023).
- **Concurrent access**: Two or more callers invoking the refresh operation
  simultaneously — MUST dedup to exactly one network request
  (auth-client-027). A refresh racing a clear of the token bundle (logout) —
  MUST NOT resurrect the session (auth-client-031). A refresh racing another
  refresher's or a fresh login's write of the token bundle — MUST adopt the
  winner's token rather than clobber or wrongly clear it (auth-client-032,
  auth-client-034). A session-change subscriber that unsubscribes another
  subscriber from inside its own callback — MUST NOT suppress delivery to
  that other subscriber for the in-progress announcement (auth-client-020).
- **Error states**: Every network call in this recipe that can fail (the
  refresh POST, the base authenticated request helper, the SSO code
  exchange, every central-login step, the silent-restore preflight check,
  every account-security operation, every MFA/passkey operation) MUST
  surface a typed HTTP error (status + code) or a plain error with an
  extracted/fallback message to its caller — none silently drops a non-2xx
  response's failure. The silent-restore preflight check alone fails closed
  to `false` on any error (network throw, non-200, wrong-shaped body) rather
  than propagating (auth-client-073) — a deliberate design choice (see
  Design Decisions), not an omission.
- **Offline/disconnected state**: A request that rejects at the network
  level (offline, DNS failure, connection reset) during a refresh — MUST be
  reported via unconditional error reporting and MUST clear the token
  bundle rather than leave a token the client can no longer confirm is still
  valid (auth-client-036). The same network-level failure during the SSO
  code exchange — MUST retry exactly once after 750ms before giving up
  (auth-client-050); an HTTP-level failure (the server responded) is never
  retried, because the one-time exchange code is already spent
  (auth-client-051).
- **No interactive host environment available** (a web-specific edge case —
  server-side rendering, or storage blocked by private browsing — with no
  native-platform analog): marking/clearing the once-per-tab restore guard,
  stashing/taking the return-to value, and beginning a provider-link's nonce
  stash MUST all swallow a thrown storage exception; beginning a
  provider-link specifically MUST fail closed (return `false`, never
  navigate) rather than start an OAuth round-trip whose CSRF completion
  check is guaranteed to fail (auth-client-098).

