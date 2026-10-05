
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `slug` | string or none | — (required) | Service identifier; a falsy value disables the query. |
| `hours` | number (hard-coded) | `24` | History window sent in the `hours` query parameter; not configurable. |
| Status API provider (client / base path) | injected client / string | default client, base path `/api` | Injected through the app's API context; determines where `/history` is resolved and allows a test double. |
| Shared cache | injected cache context | library defaults | Supplied by the host; controls retry, freshness window, cache retention, and refresh triggers. |

