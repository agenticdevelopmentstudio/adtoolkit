
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` (parameter to `pingHeartbeat`) | `string \| null` | none — caller-supplied, required | The check-in URL to ping. `null` or an empty string disables the feature entirely for that call. This file never reads an environment variable itself. |
| `HEARTBEAT_URL` | environment variable, read by `config/env.ts`'s `heartbeatUrl` getter (external to this file) | unset → `null` | The environment variable the shipped `StatusConfig` implementation reads (via `optional(env.HEARTBEAT_URL)`) to produce the `url` value that `cycle-runner.ts`'s `runMonitorCycle` (external to this file) passes into `pingHeartbeat` as `config.heartbeatUrl`. |
| `HEARTBEAT_TIMEOUT_MS` (module constant) | `number` | `5_000` | Fixed per-request deadline via `AbortSignal.timeout`; not configurable per call and has no environment override in this file. |

