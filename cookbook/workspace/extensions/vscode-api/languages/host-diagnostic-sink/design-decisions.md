
**Decision**: `HostDiagnosticSink` is a distinct type from `MainThreadDiagnostics`, rather than `MainThreadDiagnostics` firing the emitter itself from its eight mutation call sites.
**Rationale**: per the source's own doc comment, this reuses the `ExtensionDiagnosticSink` seam an earlier task already built instead of laying a second notification path beside it, and it means a future host-side source of diagnostics that never goes through `MainThreadDiagnostics` (the analogue of upstream's `$acceptMarkersChange`) reaches extensions for free by calling the same sink.
**Approved**: pending

**Decision**: `diagnosticsChanged(for:)` logs before firing, and keeps the log line rather than removing it now that a real consumer of the emitter exists.
**Rationale**: per the source's own doc comment, the log line is "the host's own record, and it is the only observable left when no extension has subscribed — which... is exactly when the emitter drops the event on the floor" (per `ExtensionEventEmitter.fire`'s zero-listener guard, specified in the `extension-host-vs-code-api-extension-event` ingredient). Keeping it means a diagnostics change is never completely silent from the host's own perspective, even when no extension is listening yet.
**Approved**: pending

**Decision**: `HostDiagnosticSink.init(emitter:)` takes `emitter` with no default value.
**Rationale**: per the source's own doc comment, one emitter is meant to be shared by this sink and by every `MainThreadDiagnostics` built for the same host; a privately constructed default emitter would compile but silently disconnect the sink from the adaptors it is meant to notify, defeating the reason `emitter` is a constructor parameter at all.
**Approved**: pending

**Decision**: `diagnosticsChanged(for:)` has no guard on an empty `uris` array.
**Rationale**: not documented in the source beyond the absence of a guard; every one of `MainThreadDiagnostics`'s eight call sites already guards on `!affected.isEmpty` before calling the sink, so in the given production wiring this method is never actually called with an empty array. The method itself still fires unconditionally, which is a fact about this file worth recording (see Edge Cases) even though today's one caller never exercises it.
**Approved**: pending

