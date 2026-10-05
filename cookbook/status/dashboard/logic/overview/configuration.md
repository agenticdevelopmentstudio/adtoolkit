
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `problems` | a list of problems | none (required) | The problems a pane is showing, as assigned severities by the server. |
| `activity` | a list of activity rows | none (required) | The board's activity rows. |
| `sinceMs` | a number | none (required) | Window-start time; the caller passes the board's own activity-window start. |
| `fromMs` / `toMs` | a number | none (required) | Window bounds; the caller passes the board's own reported window start and end. |
| `state` / `count` | a sign state / a number | none (required) | Inputs to the headline operation. |
| `platform` / `environment` | a text value / a text value or absent | none (required) | Deploy provider and environment target. |
| 48-hour day threshold | constant | 48 | Minimum hours before the caption switches to days, compiled in. |

The module reads no environment variables or settings keys and takes no injected dependencies. It imports only shapes/types from elsewhere.

