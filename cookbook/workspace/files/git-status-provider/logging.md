
Subsystem: the host application's bundle identifier (falls back to the
literal string `"nil"` if unset; see Platform Notes for the exact mechanism
used on Apple platforms) | Category: `GitStatusProvider`

| Event | Level | Message |
|-------|-------|---------|
| the underlying status check succeeds | info | `Git status: <fileCount> files, <dirCount> directories` |
| the underlying status check fails with any error other than a cancellation | error | `Git status failed for <repoRoot.path>: <sanitized error description or type name>` |

The companion color mapping performs no logging of its own.

