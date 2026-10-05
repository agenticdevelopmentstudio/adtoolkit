
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RETIRED_KEYS` | `readonly ["adh-activity-v1"]` (module constant, not exported) | `["adh-activity-v1"]` | The keys to purge. Changing it means editing the source. The caller cannot supply it. |
| `window.localStorage` | Web Storage (environment) | The browser's per-origin storage | Injected by the environment. It may be missing (SSR) or throw on access (storage denied). |

