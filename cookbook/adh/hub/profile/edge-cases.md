
- **Null and empty input — the workspace option**: MUST take the same no-query branch whether the
  options are entirely omitted or the workspace option is the empty string `""`, since an empty
  string is falsy and the workspace-query builder's check is a plain truthiness test.
- **Null and empty input — a social-link input's `handle`/`sortOrder`**: `handle` MUST be sent as
  the empty string unchanged when the caller supplies one (per the client's own test fixture,
  `handle: ""`); `sortOrder` MUST be omitted from the serialized body entirely when the caller does
  not supply it, since serializing to JSON drops an absent key.
- **Null and empty input — resolving an empty grant list**: MUST return `"only-me"`, per
  `privacy-level-resolution-default`.
- **Boundary values — `audienceMask` bit combinations**: resolving a privacy level MUST test only
  bits 0 and 1; a mask with only higher bits set (e.g. `4`) MUST fall through to `"only-me"`, and a
  mask with bit 0 set together with any higher bits (e.g. `5`) MUST still resolve to `"public"`,
  since the bit-0 check runs first and unconditionally.
- **Concurrent access**: this domain holds no shared mutable state beyond its fixed constants
  (`module-holds-no-mutable-state`), so two calls made together cannot race on anything inside this
  domain itself. Two concurrent privacy-grant-set or social-link/address-create calls for the same
  target SHOULD be expected by a caller to follow ordinary HTTP write semantics with no
  client-side sequencing — the last response the caller applies wins; no ordering guarantee is
  implemented anywhere in this domain, so this is a fact about caller responsibility, not a
  behavior this module enforces.
- **Error states — dependency failure**: this domain catches no rejection from the shared
  authenticated request client; a non-2xx backend response, a network failure, or a malformed
  response body all MUST propagate unmodified to the caller, per `violation-handling-inherited`.
- **Offline or disconnected state**: no call in this domain guards against a network-level
  rejection; a connectivity loss mid-call MUST propagate as an unhandled rejection out of every
  exported operation, with no retry, queuing, or offline-specific handling.
- **No timeout**: no call sets a deadline or cancellation signal; a reachable-but-unresponsive
  backend MUST leave the call pending indefinitely as far as this domain is concerned.
- **No cancellation**: no exported operation accepts a cancellation signal, so a caller MUST NOT
  be able to cancel an in-flight request through this domain.
- **No retry beyond the inherited 401 waterfall**: every call issues exactly one request (plus,
  on a `401`, whatever single refresh-and-retry the shared authenticated request client itself
  performs, outside this domain); nothing in this domain MUST retry a network failure or a
  non-401 error status.

