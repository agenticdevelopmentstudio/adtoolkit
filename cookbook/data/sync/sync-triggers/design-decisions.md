
**Decision**: Each trigger is a separate class behind a one-member `SyncTriggerSource` protocol rather than options on the engine.
**Rationale**: The engine attaches any number of sources through `attach(_:)`, so hosts can add their own (for example a push-notification source yielding `.hostSpecific`) without engine changes, and Network.framework stays confined to `ConnectivityTriggerSource.swift`.
**Approved**: pending

**Decision**: The periodic source tears itself down in `deinit`; the connectivity source does not, and the manual source has no `stop()` at all.
**Rationale**: The periodic task captures only the local continuation, so the source comment states that calling `stop()` from `deinit` "never resurrects `self`". The manual source's doc comment says it "Holds no resources (no task, no OS handle)", so there is nothing to stop. The connectivity source's lack of a `deinit` is the source as written; hosts call `stop()` explicitly.
**Approved**: pending

**Decision**: The connectivity source yields only on an observed not-satisfied → satisfied transition, never on the first update.
**Rationale**: The doc comment states it "Emits .connectivityRestored on each unsatisfied→satisfied transition". Starting the previous-status flag as unknown means launching online does not produce a spurious kick; hosts sync at launch by other means.
**Approved**: pending

**Decision**: Streams use unbounded buffering and sources do no debouncing.
**Rationale**: `AsyncStream.makeStream(of:)` is called without a buffering policy. Coalescing belongs to the engine, whose `kick(reason:)` folds any kick that arrives during a running cycle into one pending follow-up.
**Approved**: pending

