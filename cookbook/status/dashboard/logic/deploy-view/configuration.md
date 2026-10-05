
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `deploys` | a list of deploy records | none (required) | The deploy rows to summarize or correlate, supplied by the board. |
| `nowMs` | a number | none (required) | Client clock in epoch ms, used by the platform-summary operation for stale-in-flight demotion. |
| `probeIntervalMs` | a number, or absent | absent (600 000 ms window) | Backend probe cadence. The demotion window is the greater of 600000 and five times this value. |
| `ep` | an endpoint shape | none (required) | The endpoint's configured platform, deployProject and environment. |
| Platform order list | a constant list | `["vercel", "cloudflare-pages", "railway", "crunchy"]` | Compiled-in section order for known platforms. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. It composes the stale-in-flight test from the row model, and the deploy-target-key and platform-canonicalization operations from a shared canon module.

