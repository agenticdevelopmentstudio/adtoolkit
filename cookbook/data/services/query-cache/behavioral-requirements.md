
- **resource-gc-time-constant**: The exported resource-cache retention
  constant MUST equal `30 * 60 * 1000` (1,800,000 ms).
- **query-defaults-stale-and-retry**: The cache-client factory MUST
  construct a cache client whose default query options set the staleness
  window to `5 * 60 * 1000` (300,000 ms) and the retry count to `1`.
- **resource-key-gc-time-pinned**: The cache-client factory MUST pin a
  retention time equal to the resource-cache retention constant for every
  query whose key begins with one of the configured long-retention key
  prefixes (see Configuration; the shipped default prefixes are
  `resource-list` and `resource-item`), before returning the client, so
  every query keyed under any such prefix — including one minted by a
  prefetch or a direct cache write with no observer of its own — uses that
  retention time rather than the client-wide retention default.
- **server-client-per-call**: The singleton cache accessor MUST return a
  newly constructed cache client from the cache-client factory on every call
  made with no interactive host environment present, and MUST NOT reuse a
  client across such calls.
- **browser-client-singleton**: The singleton cache accessor MUST return the
  identical cache-client instance on every call made with an interactive
  host environment present, for the lifetime of the module.
- **browser-client-lazy-construction**: The browser-side singleton MUST be
  constructed on the first such call to the singleton cache accessor — via
  the cache-client factory immediately followed by the session-watch guard —
  and MUST NOT be reconstructed by any later call.
- **provider-uses-singleton**: The cache provider component MUST render its
  underlying cache-provider wrapper with the singleton cache accessor's
  return value as the client it publishes.
- **provider-nesting-is-idempotent**: Rendering one instance of the cache
  provider component inside another MUST publish the identical cache-client
  instance to both levels, never two distinct clients.
- **provider-siblings-share-client**: Two independently mounted, non-nested
  trees each rendering the cache provider component MUST also resolve to the
  identical cache-client instance.
- **hook-ignores-ancestor-context**: The consumer accessor MUST return the
  toolkit singleton from the singleton cache accessor regardless of any
  cache-provider component mounted above the calling component — including
  one supplying a different cache-client instance built on the same
  underlying cache library.
- **hook-usable-without-provider**: The consumer accessor MUST return a
  usable cache client when called with no cache provider component of any
  kind mounted above the caller at all.
- **session-watch-registered-once**: The session-watch guard MUST run
  exactly once per browser-side client construction, bound at the point the
  browser singleton is created, and MUST NOT be re-bound by any later call
  to the singleton cache accessor.
- **session-watch-initial-subject**: The session-watch guard MUST
  initialize its last-seen-subject value to the result of reading the
  token's subject claim at the moment it runs.
- **session-change-clears-on-subject-change**: On every session-change
  notification, the guard's comparison callback MUST compare the current
  result of reading the token's subject claim against the last-seen
  subject, and, only when the two differ, MUST clear the browser singleton's
  entire cache and update the last-seen subject to the new value.
- **session-refresh-does-not-clear**: A session-change notification whose
  subject-claim value is unchanged from the last-seen subject — the case a
  token refresh for the same signed-in principal produces, per session-change
  subscription's own contract (see the authentication client recipe) — MUST
  NOT clear the cache.
- **cross-tab-session-watch**: The session-watch guard MUST also register
  its comparison callback against a cross-tab storage-change notification,
  so the same subject comparison and conditional clear run when another
  browser tab of the same origin writes the session storage key.

