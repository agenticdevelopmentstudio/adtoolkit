
- **Null and empty input**: Neither field of the JIT availability value is
  optional, so there is no null case there. Constructing a divergence
  catalogue entry and recording a hit both accept their string fields
  (`detail`, `area`, and so on) as plain, unvalidated strings — an empty
  string (`detail: ""`) MUST be accepted and treated as an ordinary,
  distinct row key exactly like any other string.
- **Boundary values**: A hit record's `count` has no upper bound enforced
  by recording — what happens once accumulation reaches the numeric type's
  maximum is platform-dependent (see Platform Notes); reaching that
  boundary requires on the order of the numeric type's maximum accumulated
  occurrences, which no known call site can produce in a single process's
  lifetime. Recording's zero-or-negative-count boundary (a count of exactly
  zero, or any negative value) MUST be a no-op, per
  `ledger-record-noop-nonpositive`.
- **Concurrent access**: The ledger's rows MUST be read and written only
  under mutual exclusion, and publishing's snapshot-and-send step MUST run
  under a second, separate exclusion, so recording, clearing, and reading
  called concurrently from different threads MUST NOT corrupt state or
  misorder subscriber deliveries relative to the mutations that produced
  them (see `ledger-write-serialization` and `ledger-publish-lock-ordering`).
  Two independently constructed ledger instances (for example the shared
  one and one built by a test) each own their own rows, exclusion, and
  publisher; a recording on one MUST have no effect on the other's rows.
  The process-wide cached JIT availability value and its one-time logging
  guard are both initialized exactly once even when first read from several
  threads at once — for example, several concurrently created script
  engines all triggering a degraded-state log at the same moment — so no
  additional coordination is needed for that case. Probing itself holds no
  lock and no shared mutable state, so concurrent probes MUST run
  independently with no coordination between them.
- **Error states**: Reading the hardened-runtime flag and reading the
  JIT-entitlement flag each depend on operating-system calls that can fail
  for reasons outside this component's control (an unsigned binary, a
  signature the OS cannot parse); an unreadable signature MUST answer false
  rather than throw, because this diagnosis may not invent a problem it
  cannot demonstrate. Neither the divergence catalogue nor the divergence
  ledger has any dependency capable of failing; recording, clearing, and
  reading all complete unconditionally.
- **Offline or disconnected state**: Not applicable — none of the three
  pieces opens a network connection, reads a file path, or depends on any
  connectivity state; the JIT availability value's only external dependency
  is a read of this process's own in-memory code-signing information, and
  the divergence ledger's only dependencies are an in-process log handle and
  its live-rows publisher.
- **Unbounded ledger growth**: The divergence ledger provides no automatic
  eviction, expiry, or row limit — every distinct (divergence id, detail)
  pair recorded for the life of the process occupies one row until an
  explicit clear, per its own documented intent to be "cheap: an in-memory
  table behind a lock, no persistence, cleared when the app quits." A
  session that opens many distinct documents that each trip the
  out-of-workspace-scope divergence or a semantic-token divergence MUST
  therefore grow the table by one row per distinct document identifier,
  with no bound other than an explicit clear (see Design Decisions).

