
**Decision**: `fire(_:)` queues the payload into `queue` before calling `window.openWindow(closingAfter:onClose:)`, reversing upstream's own statement order (`DebounceEmitter.fire` arms `setTimeout` before `PauseableEmitter.fire` decides whether to queue).
**Rationale**: upstream's order is safe only because a JavaScript `setTimeout` callback can never run synchronously within the call that scheduled it. `ExtensionEventWindowScheduling` makes no such promise — `ExtensionEventImmediateWindow` calls `onClose` inline, before `openWindow` returns — so opening the window first would run `closeWindow()` against a still-empty queue and lose that call's payload until the next `fire`. Queueing first closes that gap while still reproducing both of upstream's outcomes (the window opens unconditionally; a zero-listener fire is dropped, not queued) by guarding each separately instead of relying on one statement order.
**Approved**: pending

**Decision**: `ExtensionEventWindowScheduling` declares no cancellation method.
**Rationale**: upstream's `DebounceEmitter` never cancels a pending timer either — `event.ts`'s whole ruling is that a `fire` inside an open window does not touch the pending timer. Per the protocol's own doc comment, a seam that offered cancellation would invite a trailing-edge reimplementation this component exists to rule out.
**Approved**: pending

**Decision**: `subscribe` refuses a non-callable first argument by raising synchronously, where upstream (`event.ts`) validates nothing and instead throws once per delivery window from inside its own error handler.
**Rationale**: per the source's own doc comment, this follows `MainThreadCommands.swift`'s existing precedent for a callback argument, and turns a silent per-window failure the extension author never sees into one synchronous error at the call site they wrote — safe to test as `typeof === 'function'` here because this host has only one JavaScript realm.
**Approved**: pending

**Decision**: `deliver(_:)` builds the mapped `JSValue` once per distinct `JSContext` reached during a delivery, caching it for every other registration sharing that context, rather than once per listener.
**Rationale**: upstream hands every listener the same event object (one `super.fire(this._mergeFn(events))`); two listeners in one context should see one object. Two listeners in different contexts cannot share a `JSValue` at all — a `JSValue` belongs to its context — and an emitter is shared across extensions, so that case is real, not hypothetical.
**Approved**: pending

