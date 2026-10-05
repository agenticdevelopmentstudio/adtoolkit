
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Status API provider (client / base path) | injected client / string | default client, base path `/api` | Injected through the app's API context. Sets where `/integrations` is resolved and lets a test inject a double. |
| Shared cache | injected cache context | library defaults | Supplied by the host. Controls retry, freshness window and cache retention. |
| Refresh-on-returning-focus | boolean (hard-coded) | `true` | Refreshes stale data when the runtime regains focus. Not configurable. |
| Refresh All interval | number | `60000` | Shared refresh interval that also refreshes this query. Set by whoever uses Refresh All, not by Integrations. |

