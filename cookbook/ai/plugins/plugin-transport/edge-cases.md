
- **Null/empty input**: An empty headers map MUST leave the request with no
  additional header fields set beyond its own defaults. An empty body MUST
  produce a request with no body. An empty standard-input payload MUST cause
  the command path to skip the write step but still MUST close the channel's
  input (command-stdin-close). An empty arguments list and an empty
  environment map MUST be accepted as ordinary, valid values — an empty
  arguments list runs the executable with none, and an empty environment
  leaves the child inheriting the host's own environment per the replace
  policy's own documented behavior for an empty value.
- **Boundary values**: A timeout at or below zero MUST cause the wall-clock
  budget to expire immediately, per the wall-clock budget's own documented
  mapping ("at or below zero → expire immediately") — the transport passes
  the timeout through unvalidated. A timeout at or above roughly one year,
  or a non-finite value, MUST start no timer at all, per the same mapping's
  "no budget" case, so the request MUST run to natural completion or to the
  caller's own cancellation with no timed-out error ever thrown.
- **Concurrent access**: The transport MUST support an arbitrary number of
  concurrent, independent run invocations without interference, per
  stateless-invocation — each call owns its own unit of work, decoder
  instance, and (for a command spec) its own subprocess channel, with no
  state shared across calls.
- **Error states**: A non-2xx HTTP status MUST surface as an HTTP-failure
  error; a nonzero subprocess exit MUST surface as a command-failure error;
  a malformed HTTP response MUST surface as an invalid-response error; any
  other failure (a connectivity error, a channel launch failure, a framing
  error from the subprocess channel) MUST surface unwrapped, per
  raw-error-passthrough.
- **Offline/disconnected state**: If the HTTP byte stream throws mid-transfer
  (e.g. a dropped connection), the byte-pumping logic's iteration MUST
  propagate that error immediately; the trailing-remainder feed and the
  flush step MUST NOT run — any bytes still buffered in the pump's own
  accumulator are discarded, and the decoder's own internal buffer is
  likewise never flushed. For the command transport, if the channel's
  message-stream iteration throws (e.g. a framing failure surfaced by the
  subprocess channel), the command path's outer failure-recovery step MUST
  terminate the channel and rethrow that error unchanged.
- **Cancellation**: Cancelling the task that iterates the stream returned by
  running a request specification MUST cancel that run's internal unit of
  work (consumer-cancellation-propagation), which for a command request MUST
  terminate the child process eagerly (subprocess-cancellation-eager-kill)
  rather than waiting for a natural exit; in both transports, a cancellation
  observed at the cancellation-check checkpoint MUST prevent the trailing
  flush from ever running (command-finish-skipped-on-cancellation,
  byte-pump-cancellation-skips-finish) — a cancelled run never receives a
  flush of the decoder's trailing state, only whatever events were already
  yielded.

