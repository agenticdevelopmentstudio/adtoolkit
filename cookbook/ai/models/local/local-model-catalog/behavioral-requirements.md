
- **serialized-state-access**: The catalog MUST serialize access to its
  internal state (the fetch function, both TTLs, and the cache) so every
  call to the size lookup, or the internal per-server sizes lookup, on one
  instance executes without a data race, interleaved only at defined
  suspension points.
- **shared-singleton**: The catalog MUST provide one process-wide instance
  for callers that do not construct their own; it is the default used when
  the inference guard is constructed without an explicit catalog.
- **fetcher-is-injectable**: Construction MUST accept an injectable fetch
  function that asynchronously returns the response bytes for a given URL
  (or fails), defaulting to a built-in live implementation, so a caller MAY
  substitute a stub fetch function with no real network dependency.
- **default-ttls**: Construction MUST default the success TTL to `300` and
  the failure TTL to `60` (seconds) when the caller does not override them.
- **live-fetcher-request-shape**: The built-in live fetch implementation
  MUST issue a `GET` request with a timeout of `5` seconds, and MUST fail
  when the response is not a successful (HTTP `200`) response.
- **size-lookup-short-circuits-on-unknown-sizes**: The size lookup MUST
  return nothing, without attempting the size resolution, when the
  per-server sizes lookup returns nothing for the given base URL; otherwise
  it MUST return the resolved size for that model within those sizes.
- **cache-key-is-the-raw-base-url**: The cache MUST key entries by the exact
  base URL string passed in, with no normalization applied to the key
  itself. The native tags URL derivation trims whitespace, trailing slashes,
  and a trailing `/v1` when deriving the fetch URL, but that normalization
  is not reflected back into the cache key — two base URL spellings that
  resolve to the same native tags URL (e.g. with and without a trailing
  slash) MUST be cached and fetched independently of one another.
- **cache-freshness-window**: For a cached entry, the per-server sizes
  lookup MUST treat it as fresh — returning its sizes without fetching —
  only when the elapsed time since it was fetched is strictly less than the
  failure TTL if that entry recorded a failed fetch, or strictly less than
  the success TTL otherwise; an entry aged exactly the success TTL or
  failure TTL seconds MUST be treated as expired, not fresh.
- **unresolvable-base-url-is-uncached**: When the native tags URL derivation
  cannot resolve a URL for the given base URL (e.g. an empty string, or a
  string that trims to empty once a trailing `/v1` and slashes are
  stripped), the per-server sizes lookup MUST return nothing immediately,
  without attempting a fetch and without creating or updating a cache entry
  for that base URL.
- **fetch-throw-yields-no-data**: When a fetch attempt fails, the
  per-server sizes lookup MUST treat the attempt as having produced no data
  rather than propagating the failure to its own caller.
- **empty-parse-is-treated-as-failure**: When a fetch attempt succeeds but
  the response parses to an empty set of sizes, the per-server sizes lookup
  MUST treat the attempt identically to a fetch failure: the resulting cache
  entry MUST be marked as a failed fetch and MUST be re-checked on the
  failure TTL cadence, not the success TTL.
- **stale-while-error**: When an attempt yields no data for a base URL that
  has a prior cached entry, the per-server sizes lookup MUST retain that
  entry's last known sizes rather than clearing them.
- **never-known-stays-nil**: When an attempt yields no data for a base URL
  with no prior cached entry, or whose prior entry's sizes were already
  unknown, the per-server sizes lookup MUST cache and return nothing for
  that base URL.
- **every-attempt-refreshes-the-timestamp**: Every time the per-server sizes
  lookup performs a fetch attempt — whether it succeeds, fails, or parses to
  an empty set — it MUST replace any prior entry for that base URL with a
  new one recording the current fetch time and whether that attempt failed.
- **first-lookup-always-fetches**: The per-server sizes lookup MUST attempt
  a fetch (subject to unresolvable-base-url-is-uncached) the first time a
  base URL is looked up, since no cache entry exists yet to satisfy
  cache-freshness-window.
- **size-tolerates-latest-suffix**: The size lookup MUST resolve a size for
  a model when the parsed sizes only contain that model name suffixed with
  `:latest` (delegated to the model server helper's size resolver).

Three concerns the catalog's own purpose calls for are not handled; each is stated below as current behavior and recorded as a pending Design Decision:

- **concurrent-fetch-deduplication**: The per-server sizes lookup checks the cache for freshness, then waits on the fetch, and only afterward writes the new entry. Because that wait is reentrant, two concurrent lookups for the same expired or uncached base URL can both observe the same pre-fetch cache state and both trigger a fetch; the entry that ends up cached is whichever call's write executes last, not necessarily the one from the most recently issued request, and the server is hit twice (or more) for one logical refresh. No in-flight-request tracking or coalescing exists.
- **base-url-locality-is-unenforced**: The catalog never calls the model server helper's loopback-detection check before deriving a tags URL from the base URL and issuing a fetch. A caller passing a non-loopback base URL (by misconfiguration or a future provider that reuses this component) causes an outbound request to that remote host on every cache miss. The inference guard's own stated assumption (one request to a loopback provider) states the same locality without enforcing it.
- **fetch-error-is-fully-swallowed**: A failed fetch attempt discards whatever error it produced (a timeout, a connection failure, a non-200 status, or any error a substituted fetch function raises) with no log and no diagnostic, so a caller cannot distinguish a refused connection from a server that returned no models or a response that failed to parse.

