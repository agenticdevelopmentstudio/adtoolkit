
**Decision**: a disposed `DiagnosticCollection`'s methods (`set`/`delete`/`clear`/`get`/`has`/`forEach`) are inert no-ops (`get`/`forEach` answer `undefined`, `has` answers `false`, `set`/`delete`/`clear` mutate nothing and notify no one), rather than throwing the way `extHostDiagnostics.ts`'s `_checkDisposed()` makes every method of a disposed collection throw.
**Rationale**: the task's own prose-only behaviors to port were the undefined-removal semantics, the array-overload merge semantics, and `get`'s absent-is-`undefined` contract; a disposed-collection throw was not among them. `MainThreadWindow.showStatusBarItem`'s own precedent — "a disposed item ignores this call" — is cited directly in the source as the reason to choose quiet inertness over inventing a new throw this task was not asked for.
**Approved**: pending

**Decision**: an empty `clear()` and an empty `dispose()` (no `Uri`s actually affected) do not notify the sink, where upstream (`extHostDiagnostics.ts`, `:48`) fires unconditionally.
**Rationale**: the shared `onDidChangeDiagnostics` emitter is keyed by `Uri`; an empty affected set contributes nothing to it whether or not the sink is called. The source's own doc names the cost if this reasoning is ever wrong — a hypothetical consumer that counts `clear()`/`dispose()` *calls* rather than changed `Uri`s would under-count — and states plainly that nothing in the current host does that.
**Approved**: pending

**Decision**: the array-taking `set` overload's cleanup of an emptied *previous* `Uri` never runs for the final `Uri` in a sorted batch (there is no following transition to trigger it), and this asymmetry is kept rather than "fixed" to run unconditionally after the loop.
**Rationale**: this is upstream's own behavior (`extHostDiagnostics.ts`'s `applyEntries`/`_compareIndexedTuplesByUri` predecessor), not a bug introduced in this port; matching upstream's edge-case behavior exactly, asymmetry included, is the stated goal of the port rather than an independent judgment about what the "correct" cleanup rule should be.
**Approved**: pending

**Decision**: `forEach`'s callback receives the collection itself (its third argument) by reading `JSContext.currentThis()` at call time rather than by capturing the `JSValue` the collection object was built as.
**Rationale**: `JSValue(newObjectIn:)` returns an autoreleased wrapper; the strong references keeping the JavaScript object alive (the context, and the JS-side variable holding it) hold nothing in Swift, so a captured reference — even a weak one — can die before the next autorelease-pool drain while the JS object lives on, making every later `forEach` call on that same collection silently iterate nothing. Reading the live receiver at call time has no such window.
**Approved**: pending

