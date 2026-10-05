
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Endpoint input (every export) | endpoint-like shape (or its two-field subset for the opt-out fold) | none (required) | The endpoint row to fold or classify |
| Monitoring-switch field | boolean or unset | unset (treated as active) | The site's master monitoring switch; only `false` means paused |
| Ignore-warning field | boolean or unset | unset (treated as not ignored) | The per-endpoint "Ignore" opt-out |
| Engine classifier | shared engine module | the shared engine | Supplies the status operation, its result type, and the base endpoint-like shape; not injectable |

No environment variables, settings keys or injected dependencies are read.

