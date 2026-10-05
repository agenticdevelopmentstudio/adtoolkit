
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| Status API client | injected dependency | same-origin client, base path `/api` | Resolves `/live`, `/live/check` and `/live/stream`; also the store key |
| Shared cache context | injected dependency | none (required) | Holds the `["live"]` poll cache |
| `POLL_INTERVAL_MS` | named constant (ms) | `60000` | Fallback poll cadence and client-estimate offset |
| `CHECK_SAFETY_MS` | named constant (ms) | `200000` | Spinner backstop for a started check (the backend's cycle budget is max(3× probe interval, 2 min), plus margin) |
| `STREAM_REOPEN_MS` | named constant (ms) | `3000` | Delay before recreating a permanently closed stream connection |
| Poll retry count | number | `1` | Poll retries before an error is reported |
| Streaming support | environment capability | platform-provided | Absent (server rendering, some test environments) means no stream connection and poll only |

