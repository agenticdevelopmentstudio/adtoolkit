
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Destination (parameter to the flush operation) | string or null | none — caller-supplied per call | The webhook target for that flush. `null` disables delivery for that call while leaving the queue intact for a later flush with a non-null destination. This module never reads configuration itself. |
| `ALERT_WEBHOOK_URL` | environment variable, read by configuration external to this module | unset → `null` | The environment variable the shipped configuration reads to produce the destination value this module's external callers pass into the flush operation. |
| `ALERT_TIMEOUT_MS` (module constant) | number | `5_000` | Fixed per-POST deadline; not configurable per call and has no environment override in this module. |
| `MAX_QUEUED` (module constant) | number | `100` | Fixed queue bound; not configurable per call. |

