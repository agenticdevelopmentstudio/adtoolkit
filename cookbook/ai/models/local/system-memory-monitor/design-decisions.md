
**Decision**: `level(for:)` checks `.normal` before `.critical` and
`.warning`, so a coalesced mask containing `.normal` alongside either or
both of the other bits still resolves to `.normal`.
**Rationale**: Per the type's doc comment: the pressure source fires on
transitions, so when several transitions coalesce into one delivered mask,
the `.normal` bit means the window *ended* at normal — a fall is always the
later event when a raise and a fall coalesce — so `.normal` must win the
latch, or a raise-then-fall pair would latch `.warning`/`.critical` forever.
**Approved**: pending

**Decision**: In the Swift implementation, `SystemMemoryMonitor` is
declared `@unchecked Sendable` rather than relying on the compiler's
automatic `Sendable` inference.
**Rationale**: The type's only mutable state, `latched`, is manually
serialized behind `NSLock` (`lock.withLock` on every read and write); the
compiler cannot verify that a hand-rolled lock provides the same guarantee a
`Sendable` conformance implies, so the author asserts it explicitly with
`@unchecked`. A port on a platform without an equivalent compiler-checked
concurrency-safety marker has nothing to assert or omit here; the
underlying requirement, `concurrency-safety-is-manually-asserted`, is what
carries the behavior forward.
**Approved**: pending

**Decision**: `init()` is left `public` and unconstrained, so a caller MAY
construct additional `SystemMemoryMonitor` instances beyond
`SystemMemoryMonitor.shared`, each with its own `DispatchQueue` and
`DispatchSourceMemoryPressure`, with no `deinit` or `source.cancel()` to
release either.
**Rationale**: The source provides no lifecycle management beyond ARC
deallocation of the instance and its stored `source` property; this is
acceptable for the production singleton (`.shared`, alive for the process's
lifetime) and for short-lived test instances (e.g.
`SystemMemoryMonitorTests.liveMonitorReportsRealRAM`), but the source itself
does not document or bound how many independent subscriptions repeated ad
hoc construction would accumulate.
**Approved**: pending

