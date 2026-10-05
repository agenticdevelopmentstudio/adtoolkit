
- **Null and empty input**: An empty model name or base URL is not
  special-cased by the verdict operation; it is forwarded to the model
  catalog's size lookup, which is expected to yield "unknown" (unknown
  size), so the verdict operation MUST fall through to the unknown-size,
  fail-open path exactly as for any other unrecognized model (MUST). A
  settings reader that returns no value for either threshold key MUST fall
  back to the documented 25%/50% defaults (MUST, see
  `threshold-fallback-on-missing-or-invalid`).
- **Boundary values**: A deadline of exactly `0` or negative MUST be clamped
  to a zero-duration timer rather than crash (MUST, see
  `deadline-clamped-to-nonnegative`). Because the deferred-reason message
  truncates the deadline toward zero when formatting it as whole seconds,
  any deadline under one second (e.g. a test's `0.1`) reads as `"...its 0s
  deadline..."` in the thrown reason string — a direct, undocumented-
  elsewhere consequence of that truncation that this recipe records rather
  than idealizes. The warn/block percentage values read from settings are
  forwarded to the model-fit policy unclamped; the guard itself performs no
  range validation (e.g. rejecting a negative or >100 percentage) on these
  values.
- **Concurrent access**: Concurrent exclusive-run callers on one instance
  MUST be serialized to at most one running operation at a time, in FIFO
  admission order (MUST, see `mutual-exclusion`, `fifo-admission-order`).
  The verdict and pressure-only recheck operations do not touch the busy
  flag or waiter queue, so they MUST remain callable, and MUST be able to
  complete, at any time — including while another call holds the exclusive
  lock (MUST, see `verdict-independent-of-exclusive-lock`). Calling the
  exclusive-run operation reentrantly on the same instance from within an
  operation it is already running for is not detected and deadlocks with no
  time bound, since the deadline only covers time spent running a granted
  operation, never time spent waiting to acquire the lock (SHOULD NOT, see
  `no-reentrant-acquisition`).
- **Error states**: If the model catalog's size lookup cannot determine a
  size (an unreachable or unrecognized local server), the verdict operation
  treats that identically to a model it has never seen — size unavailable,
  fail-open under normal pressure (MUST, see `unknown-size-fail-open`). If
  the operation inside an exclusive run fails before its deadline elapses,
  that exact error MUST propagate to the caller and the deadline timer MUST
  be cancelled without effect (MUST, see `operation-result-propagation`).
- **Offline or disconnected state**: The guard makes no network call of its
  own; an unreachable local model server is observed only indirectly, as the
  model catalog's size lookup returning "unavailable," and is handled
  identically to any other unknown-size case above. The verdict operation
  itself never fails and is never cancellation-checked, so if the calling
  operation is cancelled while the verdict operation awaits the size
  lookup, the verdict operation still completes and returns an ordinary
  verdict (typically allow) rather than raising a cancellation error — this
  is a direct consequence of the verdict operation's non-failing contract,
  not a bug.
- **Cancellation and timeouts**: A waiter cancelled while parked MUST fail
  its acquire call with a cancellation error without ever running the
  operation (MUST, see `parked-cancellation-throws`). An operation that
  exceeds its deadline MUST be cancelled and reported as a deferred refusal,
  and the lock MUST still be handed off to the next waiter afterward (MUST,
  see `deadline-enforced-per-operation`, `deadline-cancellation-preserves-
  handoff`). A caller's own cancellation, checked once immediately after
  acquire succeeds, MUST prevent the operation from ever running for that
  call (MUST, see `post-acquire-cancellation-check`).
- **Missing file or unreachable server**: Not directly observable inside the
  guard itself — a missing local model file or an unreachable server
  surfaces only as the model catalog's size lookup returning "unavailable,"
  handled as described under Error states and Offline/disconnected state
  above.

