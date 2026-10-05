
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Injected API client | API client | resolved via dependency injection; same-origin client at the default base path (`/api`) | Transport for the `GET /status` request; overridden via the client provider's client or base path. |
| Shared cache (injected) | cache | host cache provider | Owns caching, retry, stale time and garbage collection; the state sets none of these. |
| Cache key | fixed | `status` | Fixed cache key; not exported as a constant. |
| Refetch on focus | boolean | `true` | Fixed in the source; not caller-configurable. |

The state takes no arguments and reads no environment variables.

