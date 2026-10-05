
- **Null and empty input**: An unknown disk size MUST short-circuit the
  tier and fit-info computations to nothing and MUST make the verdict
  computation fail open to `allow` whenever pressure is `normal` (MUST,
  see `tier-unknown-size`, `verdict-allow-non-block-tier`). An empty model
  name string (`""`) is not validated or rejected anywhere: the verdict
  and picker-label computations MUST interpolate it verbatim into the
  reason string or label exactly as any other string, since neither
  branches on it (MUST).
- **Boundary values**: A percentage exactly equal to the warn threshold
  MUST classify as `warn`, not `ok`, and a percentage exactly equal to the
  block threshold MUST classify as `block`, not `warn`, because the tier
  computation compares with "at or above," not "strictly above" (MUST,
  see `tier-classification`). Physical RAM of `0` MUST yield an unknown
  tier (so the verdict computation fails open) and MUST make the
  RAM-percentage computation return `0`, regardless of disk size (MUST,
  see `tier-zero-ram`, `ram-pct-zero-ram`). A negative disk size, or a
  negative or over-100 warn/block threshold, is not validated or rejected
  anywhere; the estimated-bytes computation, the tier computation, and the
  percentage arithmetic all proceed unguarded, so a negative disk size
  necessarily produces a negative percentage, which both "at or above"
  comparisons read as `ok` (fact, not a MUST — no validation branch exists
  to enforce or violate this).
- **Concurrent access**: Not applicable in the mutex/serialization sense —
  this policy declares no lock or shared mutable state of any kind (MUST,
  see `namespace-isolation`); every computation reads only its parameters
  and returns a freshly computed value, so any number of concurrent
  callers are inherently race-free and require no synchronization.
- **Error states**: This policy raises no error of its own and has no
  dependency (network, file system, database) to fail against. A caller's
  own failure to determine a model's size or the machine's RAM is
  communicated to this policy only as an unknown disk size, already
  covered under Null and empty input above (fact — there is no error path
  of its own to document).
- **Offline or disconnected state**: Not applicable — this policy makes no
  network call and holds no notion of connectivity. A caller's own
  unreachable local model server surfaces to this policy only as an
  unknown disk size, identical to any other unknown-size case above.

