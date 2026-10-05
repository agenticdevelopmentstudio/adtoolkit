
- **Decision**: bound `probeEndpoints`'s fan-out to `HEALTH_PROBE_CONCURRENCY = 24` rather than probing every endpoint at once.
  **Rationale**: stated directly in the source's own comment — an unbounded fan-out "saturates Node's getaddrinfo threadpool (4 threads) and socket pool," which inflated every site's measured response time into a uniform ~2s band and tripped the degraded threshold for sites that actually answer in under 300ms. `24` is chosen against two limits at once: low enough that DNS queue depth (~24/4 = 6) stays well under the saturation point, yet high enough that a wide outage (many endpoints hanging to the full `HEALTH_CHECK_TIMEOUT_MS`) still finishes inside the calling route's `maxDuration` (60s): the comment computes "~134 endpoints × 10s / 24 ≈ 56s," versus ~67s (and a platform kill) at the previous value of `20`.
  **Approved**: pending
- **Decision**: cap every body read at `PROBE_BODY_MAX_BYTES` (`256 * 1024` bytes) and always cancel the remainder of the stream, whether the cap was hit or not.
  **Rationale**: stated directly in the source's own comment — "the health JSON and expectBody markers live in the first bytes... [w]ithout a cap, classifying 'read the whole body' lets one endless/huge response drain forever inside the cycle." Always cancelling (`capped-read-stops-at-limit`) returns the socket to the pool instead of leaving it idling half-open.
  **Approved**: pending
- **Decision**: make the whole-leg timeout cover both headers and the body read, rather than clearing the deadline once headers arrive.
  **Rationale**: stated directly in the source's own comment — clearing the deadline at headers "once let a server that answers instantly and then trickles its body forever hang the probe past every cycle budget: the worker got terminated every tick, `/health` went stale, and the supervisor restart-looped the container — one bad endpoint taking down the monitor."
  **Approved**: pending
- **Decision**: measure `responseTimeMs` only across the HTTP leg (`fetchStart` to header arrival), excluding the preceding DNS-resolution step.
  **Rationale**: stated directly in the source's own comment — "'response time' should mean how long the *site* took to answer, not how long our checker spent resolving the name."
  **Approved**: pending
- **Decision**: report a mid-stream body-read failure via `console.error` and a status-code-only fallback classification, rather than treating it as a `"down"` outage.
  **Rationale**: stated directly in the source's own comment — "the server already answered with headers, so a broken body is not evidence the site is down — and since HTTP issues carry no debounce, letting it hard-fail would open an issue (and page on-call) off one connection blip."
  **Approved**: pending

