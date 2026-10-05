
**Decision**: Both read operations bypass the local HTTP response cache.

**Rationale**: A refetch right after Add or Ignore, or on picker open, must reach the server for a fresh provider scan; the browser's HTTP cache would otherwise show stale wired, ignored and project data. (Web platform: implemented as `cache: "no-store"`.)

**Approved**: pending

---

**Decision**: The first fetch of a page load, and any fetch after an explicit arm, sends `?fresh=1`; the latch disarms only on success.

**Rationale**: A reload and the explicit Refresh must show, and Auto Configure must plan against, the live project list rather than the server's 30 s provider cache; keeping the latch armed after a failure keeps retries fresh, while later refetches in the same page load use normal caching.

**Approved**: pending

---

**Decision**: The unconfigured-partition read defaults to the cache-served path; only the Auto Configure modal sends `fresh: true`.

**Rationale**: The route shares the sibling `/deploy-projects` 30 s provider cache, so the config-status badges' 60 s poll coalesces on it instead of fanning out a provider scan per tab per minute.

**Approved**: pending

---

**Decision**: The two read operations are exposed separately from the cached state.

**Rationale**: The cached state, the imperative Auto Configure run and the badges share one URL, flag and response shape so they cannot drift.

**Approved**: pending

---

**Decision**: `verifiedPlatforms` is optional and its absence means "treat every wiring as live".

**Rationale**: A backend that predates the field sends nothing, and a provider that errored, timed out or fell back to its configured list is deliberately omitted, so a client can tell "deleted upstream" from "we couldn't look".

**Approved**: pending

**Decision**: The arm latch is cleared by every successful fetch, not only by a fetch that consumed an armed latch, so an arm made during an in-flight fetch is lost.
**Rationale**: It stands today because the success path sets the latch to false without comparing what it read. Closing it needs a decision on clearing only the arm the fetch consumed (for example a generation counter) and a test that arms during a fetch.
**Approved**: pending

