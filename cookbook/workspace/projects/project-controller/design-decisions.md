
**Decision**: Overlapping `open()`/`refreshCheckouts()` calls are serialized
by chaining each call's `Task` onto the previous one's, rather than with a
lock, semaphore, or `AsyncStream`.
**Rationale**: The doc comment on `inFlightReconcile` explains the failure
mode this avoids: without chaining, "whichever's git call happens to finish
last win\[s\], even when that is the earlier of the two calls." Chaining
makes the *later caller's* write the one left standing, regardless of which
git subprocess happens to finish first — call order, not completion order,
is the contract (`ProjectController.swift`, verified by
**reconcile-calls-chain-in-order**, vector -014).
**Approved**: pending

**Decision**: `markClosed()` is synchronous; `shutdown()` is `async` and calls
`markClosed()` as its first step rather than setting `isClosed` itself.
**Rationale**: The doc comment on `isClosed` states the reason directly: an
`async` path to setting the flag "costs a main-actor hop," during which "a
reconcile continuation already enqueued ahead of that hop would resume with
the flag still down, pass the guard, and write a dead window's checkouts
into the database." A synchronous `markClosed()`, called from the window's
close handler in the same main-actor turn that drops the controller, closes
that window (`ProjectController.swift`).
**Approved**: pending

**Decision**: `readCheckouts()` orders a non-empty result with
`found.filter(\.isMain) + found.filter { !$0.isMain }` rather than
`found.sorted(by:)`.
**Rationale**: The inline comment gives the reason: `sorted(by:)` "is
documented as not guaranteed stable, so a comparator that only orders
main-before-non-main would not reliably keep the non-main checkouts in git's
own order." Partitioning instead lets git's own order survive within each
half (`ProjectController.swift`).
**Approved**: pending

**Decision**: `onTabsDidChange` and `onTabItemsNeedRefresh` are mutually
exclusive — a reconcile fires at most one of them, never both.
**Rationale**: The doc comment on `reconcile()` states this is deliberate:
"one fires on the path that writes, the other on the path that does not."
Firing `onTabsDidChange` when nothing was actually written would make the
window "throw away a live pane tree, and every shell and file-system watcher
in it, for no reason at all"; firing `onTabItemsNeedRefresh` on the
write path would be redundant work the write path's own rebuild already
covers (`ProjectController.swift`).
**Approved**: pending

**Decision**: `branchController(forDirectory:)` and the tab-item lookup both
resolve symlinks in the directory they are handed before comparing it to a
checkout's stored (already-resolved) `directory`.
**Rationale**: The inline comment states the two routes a directory reaches
this controller by: `git worktree list` reports a fully resolved path, while
a caller's own `directory` may be "whatever a caller had lying around."
Comparing without resolving both sides would turn a real match into a miss
(`ProjectController.swift`; see
`ProjectCheckout.swift` for the same rule applied to storage).
**Approved**: pending

**Decision**: `syncBranchControllers()` reuses an existing `BranchController`
by matching on the checkout's `directory` alone, not on the whole
`ProjectCheckout` (which also hashes on `branch`).
**Rationale**: The inline comment explains why: "a checkout that switched
branch must still find its controller." Matching on the full value type
would treat a branch switch as a different checkout, discarding and
rebuilding the `BranchController` — and its live `GitStatusProvider`
subscription — on every branch change (`ProjectController.swift`).
**Approved**: pending

