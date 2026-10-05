
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Activity rows | list of activity rows | — (required) | The rows to track. The caller passes its env-filtered activity rows. |
| Hold duration at 100% | number (fixed) | `2000` (ms) | How long the bar holds at 100% after the last cohort build completes before the cohort resets. Not overridable by the caller. |

