
- **stream-draining**: The run-to-completion operation MUST install a
  dedicated pipe on both the process's standard output and standard
  error, replacing anything a caller already set on either, and MUST
  begin draining each continuously before the process starts, so that
  output written by the process is read as it arrives rather than after
  the process exits.
- **concurrent-drain-collection**: Both streams' drained chunks MUST be
  appended into one lock-protected collector so that the two streams'
  arrival callbacks — which MAY be delivered concurrently with each other
  — never race or drop a chunk.
- **termination-handler-before-run**: A callback for the process's own
  exit MUST be assigned before the process is started, so the exit signal
  cannot be missed between starting the process and beginning to wait for
  it.
- **run-throw-propagation**: If starting the process throws, the
  run-to-completion operation MUST rethrow that error to the caller
  unchanged, and MUST first clear both pipes' drain callbacks and the
  exit callback; it MUST NOT wait, drain, or return an outcome on this
  path.
- **deadline-wait-without-watchdog**: When no watchdog is supplied, the
  run-to-completion operation MUST wait for the process to exit for up to
  the timeout's number of seconds and MUST mark the run as timed out if
  that wait itself expires without the process exiting.
- **watchdog-polling**: When a watchdog is supplied, the run-to-completion
  operation MUST poll its abort condition on the calling thread at an
  interval no larger than the watchdog's configured interval, and never
  larger than the deadline's remaining time, MUST mark the run as aborted
  and stop polling the first time that condition becomes true, and MUST
  mark the run as timed out instead — without polling the condition again
  — if the overall timeout deadline is reached first.
- **exit-during-poll-is-clean**: If the process exits during a watchdog
  poll interval, the run-to-completion operation MUST leave both the
  timed-out and aborted markers false.
- **terminate-on-timeout-or-abort**: The run-to-completion operation MUST
  send the graceful termination signal if and only if the run is marked
  timed out or aborted; it MUST NOT terminate a process that exited on its
  own.
- **sigkill-escalation**: After sending the graceful termination signal,
  the run-to-completion operation MUST wait up to the fixed termination
  grace period (2 seconds) for the process to exit, and if that wait
  itself expires, MUST send the forceful termination signal to the
  process and then wait up to another termination grace period for exit.
- **status-sentinel-on-non-exit**: The outcome's status MUST be a
  dedicated never-exited sentinel value (`-1`) when the process still has
  not exited after the forceful-termination wait, and MUST be the
  process's own exit status in every other case.
- **bounded-post-exit-drain-wait**: Once the process has exited, been
  killed, or given up on, the run-to-completion operation MUST bound each
  stream's drain-completion wait to the termination grace period rather
  than waiting unboundedly for an end-of-file signal that, in the
  ordinary case, has already arrived.
- **readability-handlers-cleared**: Both pipes' drain callbacks MUST be
  cleared before the run-to-completion operation returns, on every return
  path — the throw path and the normal return path.
- **outcome-buffers-always-populated**: The outcome's standard-output and
  standard-error buffers MUST be exactly the bytes collected for each
  stream, returned regardless of status, timed-out, or aborted state — a
  killed or timed-out run's partial output MUST still be returned, not
  discarded.
- **diagnostics-trimmed-utf8**: The outcome's diagnostics field MUST
  decode the collected standard-error bytes as UTF-8, MUST fall back to
  an empty string when the bytes are not valid UTF-8, and MUST trim
  leading and trailing whitespace and newline characters from the result.
- **timedout-aborted-mutually-exclusive**: For a single run, at most one
  of the outcome's timed-out and aborted markers MUST be true — the
  watchdog branch sets at most one of the two before ending its loop, and
  the non-watchdog branch can set only timed-out; no code path sets both.
- **watchdog-parameter-default**: The watchdog parameter MUST default to
  none when the caller omits it.
- **termination-grace-fixed**: The grace period between the graceful and
  forceful termination signals, and the bound on the post-exit drain
  wait, MUST be exactly 2 seconds and is not a value the run-to-completion
  operation exposes to callers.
- **outcome-and-watchdog-thread-safe**: The outcome value and the
  watchdog value MUST both be safe to share across concurrency-domain
  boundaries, so both MAY be passed freely between concurrent callers; the
  abort condition itself MUST be safe to invoke from a concurrent
  context, and the internal collector's own synchronization (not verified
  by any compiler) is what makes sharing it across the two streams'
  arrival callbacks correct.
- **watchdog-callback-serialized**: The watchdog's abort condition MUST be
  called only from the one thread running the polling loop inside the
  run-to-completion operation, and MUST NOT be called concurrently with
  itself.
- **synchronous-blocking-call**: The run-to-completion operation MUST run
  synchronously on the thread that calls it — it offers no cooperative
  suspension point of its own, only bounded waits — so a caller MUST
  expect that calling thread (including a UI thread) to be occupied for
  the entire run, up to the timeout plus as much as two termination grace
  periods.

