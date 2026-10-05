
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| permissions | a list of permission values | required (no default) | The permissions to show, one row per entry, in the given order; captured once at construction and never re-read afterward. |
| checker | a status-checking dependency | a freshly constructed system-backed checker | Supplies live status reads and grant requests to every row and to the panel's own action handling. |

