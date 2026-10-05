
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Manager construction | — | — | No parameters; the manager is stateless. |
| Excluded apps | set of strings (constant) | six system process names | Owner names dropped from enumeration. |
| Observer construction, window source | window-control contract | required | Window source used for snapshots and diffs; a mock can be injected. |
| Observer delegate | delegate reference (weak) | nil | Receives lifecycle events. |
| Accessibility-element lookup, pre-fetched window record | window record or nil | nil | Pre-fetched info; nil triggers a fresh window-list lookup. |
| Geometry tolerance | number (constant) | strictly less than 2 points | Position and size match tolerance for matching, backfill and title changes. |
| Match weights | integers (constants) | title 10, position 5, size 3, both-empty title 1 | Scoring weights used when picking the best-matching accessibility element. |
| Unpark x offset | number (constant) | 80 | Points right of the main screen's visible minX. |
| Launch delay | seconds (constant) | 1.0 | Wait before subscribing to a newly launched app. |
| Window-created delay | seconds (constant) | 0.5 | Wait before diffing for a new window. |

