
### Signature and Delegation

- **runs-core-sweep-first**: `runMonitorCycle(storage: Storage, opts: { fullSync: boolean; config: StatusConfig }): Promise<void>` MUST call `runCycle(storage, config, { skipDeploys: !opts.fullSync })` exactly once, and MUST do so before any other call in its body.
- **skip-deploys-mirrors-full-sync**: The `skipDeploys` value passed to `runCycle` MUST be the logical negation of `opts.fullSync` — `true` on a probe-only tick (`opts.fullSync` is `false`) and `false` on a full sync (`opts.fullSync` is `true`).
- **config-threaded-unchanged**: `runMonitorCycle` MUST pass the same `config` reference it received, unmodified, to `runCycle` and to `collectTelemetry`, and MUST pass `config.alertWebhookUrl` as the sole argument to `flushAlerts` and `config.heartbeatUrl` as the sole argument to `pingHeartbeat`.
- **no-connection-lifecycle-management**: `runMonitorCycle` MUST NOT open, close, tune, or otherwise manage the underlying database connection itself; every persistence operation it triggers MUST be reached exclusively through the `storage: Storage` parameter it was given.
- **resolves-void-on-success**: When every step it runs completes without throwing, `runMonitorCycle` MUST resolve its returned `Promise<void>` with no value; it defines no success payload beyond "did not reject."

### Alert Flush and Failure Propagation

- **alerts-flushed-every-call**: `runMonitorCycle` MUST call `flushAlerts(config.alertWebhookUrl)` exactly once, inside a `finally` block that wraps only the `runCycle` call, so the flush runs whether `runCycle` resolves or rejects.
- **core-sweep-failure-propagates**: If the `runCycle` call rejects, `runMonitorCycle` MUST rethrow that same rejection to its own caller after the `finally` block's `flushAlerts` call has completed, and MUST NOT execute any statement after the `try`/`finally` block for that call.

### Full-Sync-Only Phase

- **full-sync-phase-requires-success**: The peers/telemetry/maintenance/snapshot/heartbeat phase (`fetchPeers`, `collectTelemetry`, `storage.maintenance.runMaintenance`, `storage.maintenance.snapshotIfDue`, `pingHeartbeat`) MUST run when, and only when, `opts.fullSync` is `true` and the `runCycle` call did not reject; it MUST NOT run on a probe-only tick regardless of whether `runCycle` succeeded, and MUST NOT run at all when `runCycle` rejected, regardless of `opts.fullSync`.
- **full-sync-phase-sequential-order**: When the full-sync phase runs, `runMonitorCycle` MUST await, in exactly this order, `fetchPeers(storage)`, then `collectTelemetry(storage, config)`, then `storage.maintenance.runMaintenance()`, then `storage.maintenance.snapshotIfDue()`, then `pingHeartbeat(config.heartbeatUrl)` — each call fully awaited to completion before the next begins; none of the five MAY run concurrently with another.
- **heartbeat-last**: `pingHeartbeat(config.heartbeatUrl)` MUST be the last operation `runMonitorCycle` performs on a full sync; it MUST NOT be called until `fetchPeers`, `collectTelemetry`, `runMaintenance`, and `snapshotIfDue` have each completed without throwing.
- **maintenance-phase-failure-aborts-remainder**: If `storage.maintenance.runMaintenance()` rejects, `runMonitorCycle` MUST propagate that rejection to its caller and MUST NOT call `storage.maintenance.snapshotIfDue()` or `pingHeartbeat` for that cycle.
- **maintenance-uses-store-defaults**: `runMonitorCycle` MUST call `storage.maintenance.runMaintenance()` and `storage.maintenance.snapshotIfDue()` with no arguments, deferring every prune budget, chunk size, snapshot interval, and retention-count default entirely to the `MaintenanceStore` implementation it is handed.
- **maintenance-prune-logged-on-deletion**: `runMonitorCycle` MUST log, via `console.log`, the message `[maintenance] pruned <deleted> retention rows` — where `<deleted>` is `runMaintenance`'s resolved `deleted` count — when that count is greater than `0`, appending the literal suffix ` — more next cycle` when `runMaintenance`'s resolved `done` flag is `false`; it MUST NOT emit this log line when the resolved `deleted` count is `0`.

