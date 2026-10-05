
- **guard-refusal-cases**: The guard's refusal error type MUST provide
  exactly two cases, blocked and deferred, each carrying a human-readable
  reason string.
- **guard-refusal-description**: The refusal error's description MUST return
  the associated reason string unchanged for both the blocked and deferred
  cases.
- **guard-refusal-non-transport**: A guard refusal (blocked or deferred)
  MUST NOT be treated by a caller as a transport failure eligible for
  another provider path; a guard refusal is deliberately not the daemon's
  own completion error type, and it must never cascade into the CLI
  fallback path.
- **shared-default-instance**: The guard MUST provide one process-wide
  default instance, constructed from the production model catalog and
  memory monitor.
- **injectable-dependencies**: The guard's constructor MUST accept a
  substitutable model catalog and memory monitor, each defaulting to its
  production singleton, so a caller MAY construct a guard backed by fixed or
  fake behavior.
- **serialized-mutable-state**: The guard's mutable state (its busy flag and
  waiter queue) MUST be serialized so that no two operations can observe or
  mutate it concurrently — access is mutually exclusive rather than
  protected by ad hoc locking at each call site.
- **threshold-settings-override**: The verdict operation MUST read the warn
  and block percentage thresholds from the supplied settings reader under
  the model-fit policy's warn/block threshold keys and MUST use the parsed
  integer when one is present.
- **threshold-fallback-on-missing-or-invalid**: The verdict operation MUST
  fall back to the model-fit policy's default warn percentage (25) / default
  block percentage (50) when the settings reader returns no value for a
  threshold key, or returns a string that is not parseable as an integer.
- **disk-size-lookup-delegation**: The verdict operation MUST obtain the
  candidate model's on-disk size from the model catalog, and MUST treat "no
  size available" as "size unknown" rather than substituting a default
  size.
- **unknown-size-fail-open**: When the disk size is unknown (no tier), the
  verdict operation MUST return allow whenever the memory-pressure component
  alone would also allow — it MUST NOT block or defer solely because the
  size lookup failed.
- **warn-tier-log-emission**: When the computed tier is warn, the verdict
  operation MUST emit exactly one notice-level diagnostic log entry naming
  the model and its estimated resident footprint, marked as safe for public
  disclosure.
- **warn-tier-log-scope**: The verdict operation MUST NOT emit the warn-tier
  log for an ok or block tier, and MUST NOT emit it when the tier is unknown
  (size unavailable).
- **verdict-computation-delegation**: The verdict operation MUST compute its
  returned verdict by delegating to the model-fit policy, passing the
  injected memory monitor's current physical RAM and pressure level at the
  time of the call.
- **verdict-independent-of-exclusive-lock**: The verdict operation MUST be
  callable, and MUST be able to complete, without acquiring or waiting on
  the exclusive-run mutex — it reads and touches neither the busy flag nor
  the waiter queue.
- **pressure-only-recheck**: The pressure-only recheck operation MUST
  return the model-fit policy's pressure-only verdict, evaluated fresh
  against the memory monitor's current pressure level rather than any value
  cached from a prior verdict call, so it can be re-checked once inside a
  held lock's critical section.
- **mutual-exclusion**: The exclusive-run operation MUST guarantee that at
  most one operation is running at any instant across all concurrent callers
  of one guard instance.
- **fifo-admission-order**: Acquirers that begin waiting while the guard is
  busy MUST be granted ownership in the order they began waiting; a later
  arrival MUST NOT run its operation before an earlier, still-eligible
  waiter.
- **uncontended-fast-path**: A call to the exclusive-run operation made
  while no operation is running MUST proceed without parking — no waiter
  entry is created, and the busy flag is set directly.
- **direct-handoff-without-busy-gap**: On completing an operation, release
  MUST hand ownership directly to the head of the waiter queue when one
  exists, and the busy flag MUST remain set throughout that handoff; the
  busy flag MUST become unset only when the waiter queue is empty at release
  time.
- **post-acquire-cancellation-check**: Immediately after acquiring ownership
  and before the operation is invoked, the exclusive-run operation MUST
  check the calling operation's cancellation state and MUST fail with a
  cancellation error, without ever invoking the operation, if the caller was
  already cancelled.
- **release-on-every-exit-path**: The exclusive-run operation MUST release
  exactly once for every successful acquire, whether the operation returns
  normally, throws, the post-acquire cancellation check fails, or the
  deadline expires.
- **parked-cancellation-throws**: A waiter cancelled while still parked in
  the queue MUST be removed from the queue and MUST cause its acquire call
  to fail with a cancellation error, without ever invoking the operation.
- **handoff-race-cancellation-noop**: If a waiter's cancellation is observed
  after release has already removed that waiter from the queue and resumed
  it as the new owner, that cancellation MUST be a no-op; only that owner's
  own subsequent cancellation check MAY still fail and release the lock.
- **default-deadline-value**: The exclusive-run operation MUST apply a
  default deadline of 600 seconds as the wall-clock bound on one operation
  when the caller supplies no deadline argument.
- **deadline-enforced-per-operation**: When the operation has not completed
  before the deadline elapses, the exclusive-run operation MUST cancel the
  operation and MUST fail with a deferred refusal naming the deadline in
  whole seconds, rather than continuing to wait or failing with a bare
  cancellation error.
- **deadline-clamped-to-nonnegative**: A deadline value less than or equal
  to zero MUST be treated as an immediate (zero-duration) timeout rather
  than producing a negative sleep duration.
- **deadline-cancellation-preserves-handoff**: When a deadline expiry
  cancels an operation, release MUST still run afterward and hand the lock
  to the next waiter (if any), exactly as on a normal completion.
- **operation-result-propagation**: The exclusive-run operation MUST return
  the operation's value to the caller unchanged when it completes before the
  deadline, and MUST propagate any error the operation raises unchanged (not
  wrapped) when it fails before the deadline.
- **concurrency-safe-operation-and-result**: The operation and its result
  MUST be safe to run and return across the concurrent execution the guard
  uses internally to race the operation against the deadline timer.
- **no-reentrant-acquisition**: The exclusive-run operation SHOULD NOT be
  called again on the same guard instance from within an operation it is
  already running for, because the mutex provides no reentrancy detection
  and the nested call parks behind itself with no deadline covering the time
  spent waiting to acquire (only time spent running an already-granted
  operation is deadline-bound).

