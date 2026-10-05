
- **Decision**: A failed refetch keeps the `baseURL`'s last known-good sizes
  (`stale-while-error`) rather than clearing them to `nil`, while still
  shortening the retry cadence to `failureTTL`.
  **Rationale**: Per the type's own doc comment, "stale beats failing open
  for a model already known to be over budget — the server being busy is
  exactly when the guard matters most." A guard that forgot a model's size
  the moment its server hiccuped would fail open at precisely the wrong
  time.
  **Approved**: pending
- **Decision**: A successful fetch that parses to zero model entries
  (`{"models":[]}`, or an otherwise-valid-but-empty payload) is treated
  identically to a fetch failure, not as "definitively zero models."
  **Rationale**: Inferred from the effect of `parsed.isEmpty ? nil : parsed`
  combined with the file's stale-while-error framing; no comment in the
  source states this rationale directly, but the effect is unambiguous —
  an empty parse re-enters the `failureTTL` retry cadence rather than being
  cached as a confirmed "no models on this server" fact.
  **Approved**: pending
- **Decision**: The cache key is the caller's raw `baseURL` string, with no
  normalization (trailing-slash or `/v1`-suffix stripping) applied before
  the `cache[baseURL]` lookup, even though `LocalModelServer.nativeTagsURL(baseURL:)`
  performs exactly that normalization when deriving the fetch URL.
  **Rationale**: Not stated in a source comment; this is a design fact
  rather than a documented rationale — the practical effect is that a
  caller must pass a consistent `baseURL` spelling for one server to get the
  benefit of caching, or it will fetch and cache that server's sizes once
  per distinct spelling used.
  **Approved**: pending

**Decision**: Concurrent sizes lookups for one base URL are not coalesced.
**Rationale**: Two lookups can each fetch and the last write wins; closing the gap takes either an explicit acceptance that duplicate concurrent fetches are an accepted cost (the guard's call sites are not highly concurrent) or an in-flight-request cache keyed by base URL.
**Approved**: pending

**Decision**: Base URL locality is assumed, not enforced.
**Rationale**: The catalog fetches from whatever base URL it is given; closing the gap takes calling the loopback-detection check and failing closed (returning nothing) for a non-loopback base URL, or a maintainer confirming a caller outside this component guarantees locality.
**Approved**: pending

**Decision**: Fetch errors are discarded without a log.
**Rationale**: A failed fetch yields only nil or the stale sizes, leaving no signal about why the guard stopped seeing model sizes; closing the gap takes logging the discarded error (subsystem and category to be defined) or a maintainer confirming that silence is intended for this internal advisory cache.
**Approved**: pending

