
Subsystem: the host app's own bundle identifier | Category: the
coordinator or the watcher, one category per logging type, derived from the
type's own name.

| Event | Level | Message | Category |
|-------|-------|---------|----------|
| Sync applied | info | `Sync complete for <rootURL.lastPathComponent>` | coordinator |
| Change batch received | debug | `FS changes: <count> path(s) in <rootURL.lastPathComponent>` | coordinator |
| Watcher started | info | `Started file system watcher for <rootPath>` (path logged with visibility override) | watcher |
| Watcher stopped | info | `Stopped file system watcher` | watcher |
| Stream creation failed | error | `Failed to create FSEvent stream for <rootPath>` | watcher |

