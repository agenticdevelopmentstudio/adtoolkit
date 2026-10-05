
- **Data collected**: This component collects no data of its own; it relays whatever payload value a host-side caller fires (for `onDidChangeDiagnostics`, a list of changed file URLs) to whichever JavaScript listeners an extension has subscribed. It also holds each listener's JavaScript value and optional `thisArgs` JavaScript value strongly for the registration's lifetime, per its own doc comment on lifetime.
- **Storage**: This component performs no storage of its own; the registration list and the queue are in-memory only and exist for the emitter's lifetime.
- **Transmission**: Nothing here leaves the process; delivery is an in-process call from the host into a JavaScript context the same process owns.
- **Retention**: A subscribed listener's JavaScript value (and the JavaScript context it keeps alive) is retained until its `Disposable` is disposed or listeners are removed by owner; the source's own doc comment states this explicitly as "not a cycle" but a real extension-outlives-host lifetime hazard that removing listeners by owner exists to bound.

