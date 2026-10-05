
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Default TTL | number | `3600000` (60 minutes) | Fallback age-out duration in milliseconds if no user choice is stored. |
| Selectable TTL options (minutes) | list of numbers | `[1, 15, 30, 60]` | Valid age-out durations in minutes; also defines the set of permitted stored values. |
| Storage key | string | `"adh-healthy-ttl"` | Hardcoded durable-storage key for persisting the user's choice. Key is unchanged from an earlier "Healthy" feature rename to preserve existing user settings. |

