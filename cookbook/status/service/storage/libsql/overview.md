
This is the status backend's SQLite/libSQL storage layer: the ONLY part of
the package that knows the driver, the schema, and the migrations. It
exposes five operations — opening a connection (from a URL and an optional
auth token), determining whether a connection points at a local embedded
file rather than a remote database, tuning an embedded-file connection for
concurrent access (journal mode, busy-timeout, and synchronous-write pragmas
for a file shared by two independent connections), checkpointing the
write-ahead log (reclaiming its on-disk footprint), and applying pending
migrations idempotently. The schema declares every table this backend
persists to: health-check history, hourly metric rollups, polled
deployments, derived issues, editable monitoring configuration (site groups
→ monitored sites → monitored endpoints), per-platform poll-health and
production-staleness state, peer fleet-view snapshots, polled error and
analytics summaries, and a self-contained user/session/API-token/
device-authorization authentication store — plus a re-export of three
tables from a shared deploy-platform package. Every table is a plain
relational row shape with no business logic of its own; the operations and
column defaults described here are the entire contract.

