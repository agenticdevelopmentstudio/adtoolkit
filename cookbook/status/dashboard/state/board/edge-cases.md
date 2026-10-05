
- **Empty cache, request pending**: MUST report `board: null, reason: "loading"`.
- **Empty cache, request failed twice**: MUST report `board: null, reason: "unavailable"` with `error` set; the poll keeps retrying every 60 seconds.
- **Unreachable server (network error)**: The rejected fetch MUST surface through `error` after one retry; with no cached board `reason` is `"unavailable"`, and with a cached board the verdict continues to judge that board until it goes stale.
- **Browser offline**: The underlying fetch layer pauses the request (paused, not actively fetching) rather than erroring, so with no cached board `reason` MUST be `"unavailable"`, not `"loading"`.
- **Permanently failing `/api/board` after a success**: The last good board MUST remain the judged data and MUST read `"stale"` once older than the 180,000 ms threshold; it MUST NOT be reported as current forever.
- **Wedged monitor, healthy API**: A board re-stamped with a fresh `generatedAt` over an old `dataAsOfMs` MUST read `"frozen"`.
- **Nothing configured to observe**: `dataAsOfMs: null` MUST read `"no-data"`, never a green board; distinguishing a fresh install from a broken monitor is left to the consumer (for example the overview view pairing it with the live snapshot's blind indicator).
- **Unparseable `generatedAt`**: MUST read `"stale"` (fail closed in the staleness check).
- **Missing `dataAsOfMs` field (undefined rather than null)**: The exact-equals-null check does not match, the lag is not a number, and the data clock MUST read `"frozen"`.
- **Missing `probeIntervalMs`**: The data-staleness window function MUST fall back to the widest window, `300000 × 2` = 600,000 ms, so an unknown cadence can only delay the frozen verdict.
- **Boundary at exactly the read-clock threshold**: An age equal to 180,000 ms MUST NOT be stale (the comparison is strictly greater than).
- **Boundary at exactly the data window**: A lag equal to the data-staleness window for `probeIntervalMs` MUST read `"current"`.
- **Client clock skew**: A client clock running more than the 180,000 ms threshold fast MUST false-trip a healthy board to `"stale"`; one running more than that threshold slow masks a stale board. This exposure is accepted and uncorrected (per the staleness component's own documentation, see Platform Notes); the data-clock check is immune because it uses only server timestamps.
- **Burst of live frames**: Each frame MUST trigger a refetch; an in-flight read is cancelled and replaced, so a burst of N frames produces up to N requests with only the last completing.
- **Several callers active at once**: Callers sharing a cache MUST share one cached board and one poll; each active caller adds its own frame subscriber, so one frame calls `refetch` once per active caller, and the cancel-and-refetch behavior (see Platform Notes) leaves one read completing.
- **Concurrent access**: Not applicable beyond the burst cases above — this logic runs without concurrent execution, so callbacks cannot interleave with the verdict computation (see Platform Notes).
- **Malformed but parseable body**: A JSON body that does not match the board shape is passed through unvalidated; only the three clock fields are checked, and they fail closed (`"stale"` or `"frozen"`) when unparseable. Conformance of the rest is the server's contract, guarded at compile time (see Platform Notes).
- **Hung request**: No client timeout exists; the request stays in flight until the transport ends it or a frame-triggered refetch cancels it. With a cached board, the verdict still ages the board to `"stale"` because it is judged from the current time, not from request completion.

