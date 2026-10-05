
The sync engine is the client half of an offline-first sync protocol: a state
machine that runs one *cycle* at a time — pull every page of server changes
into a local mirror, reconcile the server's resource manifest against what the
host has registered, then drain the local outbox to the server and adopt the
server's row on every conflict. It owns no storage, no network code and no
credentials: persistence is injected as a store, the wire as a transport, and
wake-ups as trigger sources. Progress is reported only through an events
stream.

The recipe also covers the value types the engine's contract is written in:
the wire shapes (a cursor, a resource descriptor, a change, a pull response, a
push op, a push request, a push result, a push response), a schema-flexible
JSON payload type, a UUIDv7 id generator, and a generated resource catalog.
The product-specific enrollment and backend rules the engine serves are
specified in
[Offline Sync Client](adtoolkit://cookbook/data/sync/offline-sync-client).

Use it when a host (an app or a daemon) keeps a local mirror of server rows,
lets the user edit offline, and needs those edits pushed later without ever
being lost.

