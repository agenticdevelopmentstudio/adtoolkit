
- **Null/empty input**: the session-watch guard's initial last-seen subject
  MUST be nothing when reading the token's subject claim returns nothing at
  singleton-construction time — no signed-in principal. A later sign-in (the
  subject moving from nothing to a non-null value) MUST be treated as an
  ordinary subject change by the comparison callback's equality check, which
  carries no null-special-case, and so MUST also clear the cache.
- **Boundary values**: this component exposes no caller-adjustable numeric
  input with a valid range; the resource-cache retention constant
  (1,800,000 ms), the default staleness window (300,000 ms), and the retry
  count (`1`) are hardcoded constants in the cache-client factory, not
  boundaries on a caller-supplied value.
- **Concurrent access**: every rendering shape this component's own tests
  cover — nested cache provider components, two sibling cache-provider
  trees, and the consumer accessor with no provider at all — MUST resolve to
  the SAME browser singleton, never a second independently constructed
  client. A call to the singleton cache accessor that re-enters synchronously
  while the singleton is under construction MUST see the browser singleton
  already assigned, because the assignment on the line before the
  session-watch guard runs completes, in the runtime's single-threaded
  execution model, before any re-entrant call can execute — this is a fact
  about that execution model, not a race the code guards against
  separately. Two browser tabs of the same origin changing the signed-in
  principal at overlapping times MUST each independently clear their own
  tab's cache: the tab that wrote the change via its own session-change
  path, and every other tab of that origin via the cross-tab storage-change
  notification.
- **Error states**: this component calls no network, file-system, or
  database dependency of its own — its only external calls are reading the
  token's subject claim, session-change subscription, registering the
  cross-tab storage-change listener, and cache-client construction, none of
  which this component's tests or the authentication client's own
  documented contract for reading the token's subject claim (guaranteed to
  return nothing rather than throw on a malformed token) show as failing.
  This component therefore defines no dependency-failure path of its own; a
  downstream query's network failure is documented by the recipe for that
  query (e.g. the resource-data recipe), not here.
- **Offline/disconnected state**: the cache-client factory sets one default
  retry policy (a single retry) applied to every query built on the
  singleton cache accessor, but this component implements no
  network-reachability detection, reconnect listener, or offline queue of
  its own, and leaves the underlying cache library's own default
  reconnect-triggered refetch behavior unmodified. A caller needing offline
  resilience beyond one retry MUST layer it on its own query function, not
  on this shared client.

