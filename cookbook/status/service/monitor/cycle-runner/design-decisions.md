
- **Decision**: flush alerts in a `finally` around only the `runCycle` call, not around the whole full-sync phase.
  **Rationale**: the source comment on the `finally` block states it directly — "Deliver whatever the recorders queued even when a later phase of the cycle throws — an outage alert must not be lost to an unrelated failure." Only `runCycle`'s outage-detecting sweep ever queues an alert via `notifyIssueAlert`; the full-sync-only phase has none of its own to protect, so its failures are deliberately left to propagate uncaught instead of being wrapped in the same guarantee.
  **Approved**: pending
- **Decision**: let a full-sync-phase failure (from `runMaintenance` or any earlier step) propagate all the way to `runMonitorCycle`'s caller instead of catching it locally.
  **Rationale**: `heartbeat.ts`'s own header comment states the dead-man design directly — "a failing or wedged monitor stops pinging, and the external service... raises the alert no in-container code could." Catching the error here and continuing to `pingHeartbeat` would report success on a full sync that never actually completed, defeating that external detection path.
  **Approved**: pending
- **Decision**: call `runMaintenance()` and `snapshotIfDue()` with their default options rather than supplying explicit budgets from this file.
  **Rationale**: the row budget, chunk size, snapshot interval, and keep-count all live inside the `MaintenanceStore` implementation (`libsql/stores/maintenance-store.ts`) specifically so every caller — this cycle and the `POST /cron/maintenance` route alike — shares one tuned policy; this file has no cycle-specific reason to diverge from it.
  **Approved**: pending
- **Decision**: run the full-sync-only phase as a strict sequence, never concurrently, with `pingHeartbeat` last.
  **Rationale**: ordering is what makes the heartbeat mean "the entire full sync, including maintenance and snapshotting, completed" — running the phase's steps concurrently (e.g. via `Promise.all`) would let a hung `collectTelemetry` race a `pingHeartbeat` that had already fired, defeating the dead-man design's stated purpose of only pinging on a fully successful sync.
  **Approved**: pending

