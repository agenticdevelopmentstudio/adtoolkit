
The trigger sources are the producers that tell the sync engine when to run a cycle. Each one conforms to the `SyncTriggerSource` protocol (declared in `SyncProtocols.swift`), whose only requirement is a `kicks: AsyncStream<SyncKickReason>` property. A host constructs one or more sources and hands each to `SyncEngine.attach(_:)`, which iterates the stream and calls `kick(reason:)` for every element (see [SyncEngine](adtoolkit://cookbook/data/sync/sync-engine)).

Three concrete sources ship:

- `PeriodicTriggerSource` — yields `.periodic` once per fixed interval until stopped.
- `ConnectivityTriggerSource` — yields `.connectivityRestored` each time the network path goes from unsatisfied to satisfied.
- `ManualTriggerSource` — yields whatever reason the host passes to `fire(_:)`.

`SyncKickReason` (declared in `SyncEvents.swift`) is the value every source emits: `.periodic`, `.connectivityRestored`, `.manual`, or `.hostSpecific(String)`. It is an immutable value safe to share across threads and concurrency domains, and it is comparable for equality.

Use these when a host needs the engine to sync on a timer, on network recovery, or on demand (pull-to-refresh, app foregrounding, a push notification) without writing its own stream plumbing.

