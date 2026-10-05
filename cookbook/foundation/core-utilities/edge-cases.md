
- **Empty string as a stored secret**: `set("", forKey:)` MUST succeed, and
  a subsequent `get(forKey:)` MUST return `""`, not nothing — an empty
  string is a valid, distinct value from "absent."
- **Empty string as a version or a fold target**: parsing `""` as a version
  MUST return nothing (empty is not a valid version), while folding `""`
  MUST return `""` (empty is a valid, if trivial, fold result) — the two
  MUST NOT be conflated.
- **Version component at the arithmetic ceiling**: a component equal to the
  32-bit signed integer ceiling (2,147,483,647) MUST parse; a component one
  greater MUST NOT — the boundary is exact, not approximate.
- **Degenerate clamp range**: clamping with equal lower and upper bounds
  MUST collapse every input to that single value, never trap or produce an
  unrelated result.
- **Concurrent mutation of the secret store's global state**: `service`,
  `accessGroup`, and `legacyServices` are shared mutable state with no
  concurrency confinement of their own; concurrent mutation from more than
  one execution context without external synchronization is a documented
  data race, not a crash the type guards against.
- **Concurrent mutation of a shared encoding-skip wrapper instance**: the
  wrapper provides no concurrency-safety guarantee; sharing one instance's
  mutable stored value across concurrent contexts without synchronization
  is the caller's responsibility, not something the wrapper prevents.
- **Credential-store lookup failure that is not "not found"**: the lookup
  helper logs any status other than success and item-not-found, but `get`
  still returns nothing for that case exactly as it does for a genuine
  absence — see `keychain-get-error-ambiguity` above.
- **Secret recovered from a legacy or access-group scope**: `get` re-stores
  the recovered value under the current scope but MUST NOT delete the
  original — a second install still pointed at the old scope MUST continue
  to find its copy.
- **Unicode and control characters in a stored secret**: the secret store
  MUST round-trip a value containing multibyte Unicode, emoji, and control
  characters (newline, tab) exactly, since `set`/`get` encode/decode as raw
  UTF-8 text with no transformation.
- **Offline or disconnected operation**: not applicable — none of the six
  utilities performs networking, so there is no offline/disconnected state
  to define.

