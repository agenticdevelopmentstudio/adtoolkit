
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the input report | the integrations report, or absent | none (required argument) | The `/integrations` report; absent means not yet loaded. |
| `"cron"` check id | string constant | `"cron"` | Hardcoded id excluded from `issues`; not configurable. |

The function reads no environment variables, settings or injected dependencies.

