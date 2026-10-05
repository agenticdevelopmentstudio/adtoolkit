
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `days` | `number` | `90` | Uptime window length, sent as the `days` query parameter and used in the cache key. |
| Poll interval | — (not set) | no polling | The state never polls; refreshes come only from the platform's default triggers or a manual refetch. |
| Injected API client / base path | API client / string | default client, base path `/api` | Injected through dependency injection; determines where `/uptime` is resolved and allows a test double. |
| Shared cache (injected) | cache | platform library defaults | Supplied by the host; controls retry, stale time, cache lifetime, focus refetch, and reconnect refetch. |

