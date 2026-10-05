
Subsystem: the app's own bundle identifier (via the shared logger
factory) | Category: the manager's name

| Event | Level | Message |
|-------|-------|---------|
| A storage read or write fails | error | `"<operation> failed: <error.localizedDescription>"`, where `<operation>` is `load`, `create`, `save`, or `delete` |
| Loading notes succeeds | info | `"Loaded <count> notes"` |

