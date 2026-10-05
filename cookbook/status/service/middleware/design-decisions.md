
- **Decision**: key the rate limiter on the rightmost `x-forwarded-for`
  entry, not the leftmost.
  **Rationale**: the source comment states the reasoning directly — XFF is a
  chain each hop APPENDS to, so the leftmost value is whatever the client
  sent and is attacker-controlled; keying on it (as an earlier version did)
  let a scripted attacker rotate a forged IP per request and walk straight
  through the ceiling. The rightmost entry is the one added by the trusted
  edge hop, the last thing to touch the header before the loopback proxy
  forwards it verbatim, so it is the only value with any authority.
  **Approved**: pending
- **Decision**: sweep expired buckets on a schedule (at most once per
  `windowMs`, or when the hard cap is hit), not on every request past a size
  threshold.
  **Rationale**: the source comment states this directly — sweeping past a
  size threshold on every request turned the limiter itself into an
  O(n)-per-request cost exactly when it was under attack, which is the
  opposite of what a rate limiter should do under load.
  **Approved**: pending
- **Decision**: when the hard cap is reached with nothing expired, drop the
  entire bucket table rather than evict the oldest entries.
  **Rationale**: the source comment states this directly — every live
  bucket lapses within `windowMs` regardless, so dropping the table costs at
  most one window's worth of accounting and keeps memory bounded with O(1)
  work, instead of paying for an eviction policy to protect counters that
  are about to expire anyway.
  **Approved**: pending
- **Decision**: keep the rate limiter's state in an in-memory `Map` local to
  one `rateLimit(opts)` call, rather than a shared/distributed store.
  **Rationale**: the source comment states this directly — this is a
  single-instance backend by design, so each process bounding only the
  traffic it actually serves is sufficient; a horizontally-scaled deployment
  would give each instance its own independent ceiling rather than a
  cluster-wide one, a fact recorded here as the tradeoff of the design
  actually shipped, not an idealization of it.
  **Approved**: pending
- **Decision**: give `requireAdmin` no `gate` parameter and no credential
  resolution of its own; make it depend entirely on `requireAuth` having run
  first and populated the context.
  **Rationale**: not stated verbatim in source beyond the "Runs AFTER
  requireAuth" comment; the effect is that admin-gating is a second, cheap,
  synchronous check layered on top of the one gate call `requireAuth`
  already paid for, rather than a second credential lookup — recorded here
  as a plain fact about the code's shape, not an invented justification.
  **Approved**: pending

