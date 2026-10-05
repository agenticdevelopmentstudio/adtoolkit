
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Injected API client base path | string | `/api` | Base the `/auth/me` path is joined to. Supplied by the host, or by a test double through the client provider. |
| Shared cache (injected) | cache | none (required) | Owns the `status-auth-me` cache entry. The host supplies it. |
| Stale time | number (ms) | `60000` | Fixed in the shared session state. Not caller-configurable. |
| Retry count | number | `3` | Fixed in the shared session state. Not caller-configurable. |

The state takes no parameters and reads no environment variables or settings keys.

