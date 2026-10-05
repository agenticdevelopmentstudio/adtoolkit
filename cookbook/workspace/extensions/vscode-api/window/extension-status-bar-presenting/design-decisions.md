
**Decision**: `ExtensionStatusBarPresenting` declares exactly two members, `putOrUpdateStatusBarItem(_:)` and `removeStatusBarItem(internalID:)`, rather than one member per upstream verb (`show`, `hide`, `update`, `dispose`).
**Rationale**: the source's own doc comment states that only two of upstream's four verbs are distinct *observable effects on a presenter* — putting an item up or refreshing it, and taking one down — because `hide()` and `dispose()` both resolve to the same removal upstream ("there is no `$hideEntry`"), and task 5.5c's Ruling 7 forbids replicating `update()`'s private debounce.
**Approved**: pending

**Decision**: `ExtensionStatusBarItemRequest.color` and `.backgroundColor` are always a flat `String?` id, never a value that preserves whether the extension wrote a plain string or a `ThemeColor` object.
**Rationale**: per the struct's own doc comment, a `ThemeColor`'s `id` *is* its whole value, so nothing is lost by not keeping the original `JSValue`; remembering which shape was written is the caller's own model's job (`MainThreadWindow`'s `ExtensionStatusBarColorValue`), needed only so its getter can answer the same shape back, which this presenter-facing type has no reason to do.
**Approved**: pending

**Decision**: `putOrUpdateStatusBarItem(_:)` is called once per committed change with no debounce, in contrast to VS Code's own upstream implementation, which defers every update through `setTimeout(..., 0)`.
**Rationale**: upstream's own stated reason for deferring is to avoid a redraw per setter call across a cross-process JSON-RPC boundary; `MainThreadWindow` and its presenter share one process and one actor and call each other directly, so that reason does not transfer. A presenter that would prefer a coalesced batch may still coalesce on its own side of the seam, at whatever cost that turns out to have — a cost this file does not measure or claim is free.
**Approved**: pending

**Decision**: `removeStatusBarItem(internalID:)` must tolerate being called for an `internalID` it never received.
**Rationale**: the caller's `hide()` removes unconditionally regardless of whether the item was ever previously visible, mirroring upstream's own `hide()`, which always calls its removal RPC regardless of prior visibility. Calling `hide()` on an item that was never shown is therefore not a no-op on the presenter side from the caller's point of view, and the protocol's own doc comment states this plainly as the reason a conformer must tolerate it.
**Approved**: pending

