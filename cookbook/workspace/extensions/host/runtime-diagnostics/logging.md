
Subsystem: the host application's bundle identifier | Category: the JIT
availability value's own name, and the divergence ledger's own name,
respectively.

| Event | Level | Message |
|-------|-------|---------|
| Degraded JIT availability, first detection in the process | error | The full diagnosis message, marked safe to disclose in full. |
| Healthy JIT availability | — | No log line is written (`jit-no-log-when-healthy`). |
| A divergence's first-ever hit for a given key | info | `"Divergence from VS Code first seen: {divergence id} — {ourBehaviour}"`, marked safe to disclose in full. |
| A repeat hit for a key already recorded | — | No log line is written (`ledger-first-hit-logs-once`). |

