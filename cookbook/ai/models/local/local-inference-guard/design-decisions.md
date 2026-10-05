
**Decision**: `runExclusive`'s `deadline` bounds only the operation's own
execution once the lock is granted, not the time spent waiting to acquire
it.
**Rationale**: The doc comment states this explicitly — "`deadline` bounds
the operation's wall-clock run." Because the raw `acquire`/`release`/
`cancelWaiter` primitives are private, every caller reaches the lock only
through `runExclusive`, so every current holder is itself deadline-bound;
this gives every waiter an implicit, transitive bound on total wait time
without needing an explicit per-waiter timeout.
**Approved**: pending

**Decision**: The mutex is not reentrant, and `runExclusive` performs no
recursion or owner-task detection.
**Rationale**: This matches the semantics of a plain `NSLock`/
`DispatchSemaphore`; adding owner-task bookkeeping was not implemented, and
every current call site (`DaemonAIChat.complete`/`completeViaPlugin`) calls
`runExclusive` exactly once per request, so a self-deadlock from reentrant
use is a documented caller obligation (see `no-reentrant-acquisition`) rather
than a runtime-enforced one.
**Approved**: pending

**Decision**: `release()` hands ownership directly to the next waiter,
keeping `busy` `true` across the handoff rather than briefly setting it
`false` and letting a new caller re-acquire.
**Rationale**: Per the source comment: "Direct handoff: the head waiter
becomes the owner; `busy` never dips to false in between, so no arrival can
slip past the queue." A false-then-true toggle would open a race window in
which a brand-new, uncontended caller could acquire ahead of an
already-waiting FIFO queue.
**Approved**: pending

**Decision**: The deferred-reason message composes the deadline with
`Int(deadline)`, which truncates toward zero.
**Rationale**: This is a direct, unremarked consequence of Swift's
`Int(Double)` conversion at the message-formatting call site; the guard does
not round or special-case sub-second deadlines (e.g. the test suite's
`deadline: 0.1` reads as `"...its 0s deadline..."`), and no production host
currently configures a sub-second deadline.
**Approved**: pending

