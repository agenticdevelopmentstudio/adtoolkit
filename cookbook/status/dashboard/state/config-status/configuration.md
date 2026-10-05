
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Forwarded to both queries; `false` parks this consumer's observation without fetching. |
| Status API client (injected) | client instance | app default | Transport for all five reads; supplied by the app's API context. |
| Shared cache (injected) | cache instance | host-supplied | Owns caching, retry, stale time and any shared refresh; Config Status sets none of these itself. |
| `CONFIGURE_DATA_KEY` | cache key | — | Exported cache key for the roster query. |
| `CONFIGURE_CLASSIFICATION_KEY` | cache key | — | Exported cache key for the classification query. |

