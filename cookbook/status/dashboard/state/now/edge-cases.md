
- **Omitted argument**: Using Now with no interval argument MUST use 30,000 ms (use-now-003).
- **Explicit default**: Passing `30,000` explicitly MUST behave identically to omitting it.
- **Zero or negative interval**: Now MUST pass the value to the timer unchanged; the environment then treats it as 0 and fires as fast as its own minimum clamp allows. This produces an update on nearly every tick; Now provides no guard.
- **Non-finite interval**: Now MUST pass a non-finite value unchanged; the environment's own coercion rules apply. There is no runtime constraint beyond taking a numeric input.
- **Stopping use before the first tick**: The cleanup MUST clear the pending timer and no update MUST occur.
- **Interval change mid-period**: The elapsed portion of the old period is discarded; the next tick MUST occur a full new interval after the change (use-now-005).
- **Background throttling**: When the environment throttles timers while inactive in the background, ticks SHOULD be expected to arrive late; Now does not compensate, so the value may lag real time by more than the interval until the next tick.
- **System clock change**: Now reads wall-clock time; if the device clock jumps backward, the next tick MUST report the earlier value, so the value is not guaranteed to be monotonic.
- **Server render and hydration**: The initial snapshot is taken once during a server-rendering pass and again on the client, so the server-rendered timestamp and the client's first value can differ; Now does not reconcile them (see Design Decisions).
- **Concurrent uses**: Many callers using Now each create their own timer; there is no shared ticker, so N callers cost N timers.
- **Error states / offline**: Not applicable: Now performs no I/O and has no failure path; the underlying clock and timer operations do not throw for numeric input.

