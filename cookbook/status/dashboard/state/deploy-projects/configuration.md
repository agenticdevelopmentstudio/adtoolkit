
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` (read argument) | boolean | `true` | When false, the query does not run. |
| `fresh` (read options) | boolean | undefined (non-fresh) | Appends `?fresh=1` to bypass the server's 30 s provider cache. |
| Status API client | injected client | — (required) | Injected transport; the cached state obtains it from the app's API context. |
| Status API provider | app context | same-origin client with base `/api` | Host-supplied API client or base path. |
| Shared cache | app context | — (host supplied) | Supplies retry, garbage-collection and refetch defaults. |
| Freshness window | number (ms) | `60000` | Hard-coded freshness window of the cached state's query. |
| Cache key | string array | `["deploy-projects"]` | Hard-coded; consumers invalidate or read state by this key. |
| Latch initial value | boolean | `true` | First fetch of each page load is fresh. |

