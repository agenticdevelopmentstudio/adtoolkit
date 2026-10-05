
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hours` | `number` | — (required) | History window length, sent as the `hours` query parameter and used in the cache key. |
| Refresh interval | number (hard-coded) | `60_000` ms | Polling period while in use; not configurable by the caller. |
| `buckets` | — (not sent) | backend default | Response History sends no `buckets` parameter, so the series length is the backend route's default. |
| Status API client provider | client / base path | default client, base path `/api` | Injected through context; determines where `/response-history` is resolved and allows a test double. |
| Host cache context | shared cache | library defaults | Supplied by the host; controls retry, freshness window, cache retention window, refresh-on-returning-focus, and background polling. |

