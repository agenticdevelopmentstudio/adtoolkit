
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `points` | read-only list of points | — | Each point has an `x` label and one numeric-or-null value per series key. |
| `series` | read-only list of series | — | Each series has a `key` (the point key it reads) and a `label`; at most four. |
| `format` | function from number to string | the number as-is | Formats a value for the y axis and the tooltip. |
| `height` | number (pixels) | `240` | Plot height; the width follows the container. |

