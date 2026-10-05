
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `path` | string | required | Database file path, or `":memory:"` for a private in-memory database using a single shared connection. |
| `readers` | integer | `3` | Size of the read connection pool. |
| `readDeadline` | duration | 10 seconds | Default ejection ceiling for a top-level read. |
| `writeDeadline` | duration | 60 seconds | Default ejection ceiling for a top-level write or transaction-free write. |
| `busyTimeout` | duration (seconds) | `5` | Seconds to wait on a locked database before failing. |
| `prepare` | optional hook function | none | Runs on every connection at open, after the temp-store setting and before the ejection mechanism is installed; for app-specific setup. |
| `deadline` (per call) | optional duration | none (use the lane default) | Overrides the deadline for one top-level call; ignored on nested calls. |
| Declared display name (platform bundle metadata) | string | `"AgenticToolkit"` when absent or empty | Source of the display name and token. |
| `home` (storage-directory operation) | location | required | Directory under which the dotfolder is placed. |
| `token` (storage-directory operation) | string | the default token | Name folded to lowercase for the dotfolder. |
| Progress-check interval | constant | 1000 execution steps | Not configurable. |
| Percentile window | constant | 128 durations per lane | Not configurable. |

