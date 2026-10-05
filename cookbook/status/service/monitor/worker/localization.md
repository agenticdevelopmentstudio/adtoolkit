
This file's only string literals are three hardcoded English `Error` messages, each thrown at boot for a caller-misconfiguration condition, and each written for the developer/operator reading a crash log rather than for an end user — they route through no localization mechanism and are never displayed in any UI. The `CycleReply.error` string a failed cycle carries is not authored by this file either; it is whatever the rejected `runMonitorCycle` call's own error produced, passed through via `err.message`/`String(err)` unchanged.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `monitor worker must be spawned via worker_threads (see worker-client.ts)` | Thrown at boot when `parentPort` is `null` |
| n/a | `monitor worker spawned without workerData.db.url (see MonitorWorkerData)` | Thrown at boot when `workerData.db.url` is falsy |
| n/a | `monitor worker spawned without workerData.config (see MonitorWorkerData)` | Thrown at boot when `workerData.config` is falsy |

