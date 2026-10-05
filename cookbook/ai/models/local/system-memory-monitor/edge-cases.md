
- **Null and empty input**: The level-mapping computation takes a
  non-optional set of memory-pressure events, so there is no null case;
  an empty set matches none of `normal`/`critical`/`warning` and MUST
  fall through to a final `normal` result (MUST, see
  `unmatched-mask-defaults-normal`).
- **Boundary values**: The three-bit set `{warning, critical, normal}`
  MUST still resolve to `normal`, because the `normal` check is evaluated
  first and unconditionally short-circuits the other two (MUST, see
  `coalesced-normal-precedence`). The two-bit set `{warning, critical}`
  (no `normal`) MUST resolve to `critical`, because that check runs before
  the `warning` check (MUST, see `critical-precedence-over-warning`).
- **Concurrent access**: The pressure level MAY be read from any thread
  while the event-handling queue concurrently writes a new latched value;
  both paths MUST take the same lock, so no read observes a partially
  written value and no two writes race (MUST, see
  `latch-write-serialization`). Physical RAM is immutable, initialized
  once at construction, so concurrent reads require no synchronization and
  MUST always return the same value (MUST, see `physical-ram-source`).
  Two independently constructed monitor instances (e.g. the shared
  instance plus one created directly in a test) each own an independent
  latch and an independent underlying subscription; an event delivered to
  one instance's queue has no effect on another instance's pressure
  level.
- **Error states**: The underlying subscription-creation and activation
  calls are not failable in this component, and construction has no error
  path — there is no dependency (network, database, file system) for this
  component to report as unavailable.
- **Offline or disconnected state**: Not applicable — this component makes
  no network call; its only external dependency is the OS kernel's
  memory-pressure notification mechanism, which this component does not
  model as a connectivity state.
- **Repeated construction**: Construction MAY be invoked any number of
  times beyond the shared instance, and each instance allocates its own
  dedicated queue and memory-pressure subscription for the process's
  lifetime; the source contains no explicit teardown operation to release
  either (SHOULD, see Design Decisions — repeated ad hoc construction
  accumulates one live queue and one live pressure subscription per
  instance for as long as that instance is retained).

