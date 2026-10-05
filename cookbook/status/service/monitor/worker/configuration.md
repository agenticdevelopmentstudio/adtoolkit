
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workerData.db` | `LibsqlConnection` (`{ url: string; authToken?: string }`) | none — required | Connection descriptor handed to the `Worker` at construction. `url` MUST be a non-empty string or the module throws at boot (connection-url-required). |
| `workerData.config` | `StatusConfig` | none — required | Threaded unchanged into `runMonitorCycle` for every `CycleRequest` this worker instance processes (storage-and-config-passed-unchanged). |
| `workerData.cooldowns` | `SharedArrayBuffer \| undefined` | `undefined` → private, thread-local registry | Adopted via `attachCooldownState`. When supplied by the spawner (`MonitorWorkerClient.spawn`, external), this worker shares the same provider-cooldown state as whichever thread supplied it. |
| `CycleRequest.seq` (per message) | `number` | none — caller-assigned | Echoed back unchanged in the `CycleReply`; this file assigns it no meaning beyond matching a reply to its request. |
| `CycleRequest.fullSync` (per message) | `boolean` | none — caller-supplied | Passed unchanged as `runMonitorCycle`'s `opts.fullSync`. |

