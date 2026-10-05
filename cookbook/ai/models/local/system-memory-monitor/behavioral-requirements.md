
- **monitoring-protocol-shape**: The monitoring interface MUST declare
  exactly two read-only properties — physical RAM (an unsigned integer)
  and pressure level (a memory pressure level) — and MUST be safe to pass
  across concurrent boundaries.
- **physical-ram-source**: The physical RAM property MUST be initialized
  once, from the OS's reported total physical memory, and MUST return
  that same value for the instance's entire lifetime rather than
  re-querying the OS on each access.
- **initial-pressure-level**: A newly constructed monitor MUST report a
  `normal` pressure level until its underlying subscription delivers its
  first event, per the latch's `normal` default.
- **pressure-level-is-latched**: The pressure level property MUST return
  the most recently latched value from the last delivered memory-pressure
  event, not a live re-read of OS state on each access.
- **event-mask-subscription**: Construction MUST subscribe to exactly the
  `normal`, `warning`, and `critical` memory-pressure events, and MUST
  activate that subscription so it is live for the instance's lifetime.
- **dedicated-event-queue**: The memory-pressure subscription's event
  handling MUST run on a dedicated serial queue labeled
  `"aipluginkit.memory-pressure"`, distinct from the queue of any caller
  reading the pressure level.
- **latch-write-serialization**: Every write to the latched value MUST
  occur under the same lock that guards every read of it through the
  pressure level property, so a concurrent read from one thread and a
  write from the event-handling queue are serialized by that one lock.
- **coalesced-normal-precedence**: The level-mapping computation MUST
  return `normal` whenever the delivered event set contains the `normal`
  bit, regardless of whether `warning` or `critical` bits are also set in
  the same coalesced delivery — a fall is always the later event when a
  raise and a fall coalesce into one delivery, so `normal` MUST win the
  latch (per the component's own documented rationale).
- **critical-precedence-over-warning**: When the delivered event set does
  not contain `normal`, the level-mapping computation MUST return
  `critical` if the set contains `critical`, even when `warning` is also
  set.
- **warning-when-only-warning-set**: When the delivered event set contains
  `warning` but neither `normal` nor `critical`, the level-mapping
  computation MUST return `warning`.
- **unmatched-mask-defaults-normal**: When the delivered event set
  contains none of `normal`, `warning`, or `critical`, the level-mapping
  computation MUST return `normal`.
- **shared-singleton-instance**: A single shared instance MUST exist
  process-wide, constructed exactly once, providing one default instance
  for every consumer.
- **public-constructibility**: Construction MUST remain unconstrained and
  available to callers, so a caller MAY create additional, independent
  instances beyond the shared one.
- **concurrency-safety-is-manually-asserted**: This component MUST be safe
  to share and access concurrently across threads, backed entirely by the
  lock-guarded serialization of its latched value rather than by any
  automatic, structurally-verified guarantee — a fact the component must
  assert explicitly, since the guarantee rests on manual locking rather
  than immutability.
- **event-handler-guards-against-deallocated-instance**: The event-handling
  callback MUST hold no reference to the monitor that would extend its
  lifetime past the point the monitor is otherwise deallocated, and MUST
  return without updating the latched value once the monitor has already
  been deallocated.

