
Subsystem: the app's identifier | Category: window observer

| Event | Level | Message |
|-------|-------|---------|
| Observation started | info | `SystemWindowObserver started, monitoring <count> applications` |
| Observation stopped | info | `SystemWindowObserver stopped` |
| App launched | info | `App launched: <appName> (PID <pid>)` |
| App terminated | info | `App terminated: <appName> (PID <pid>)` |
| Window created | info | `Window created: <app> — '<title>' (ID <id>)` |
| Window destroyed | info | `Window destroyed: ID <windowID>` |
| Title changed | debug | `Title changed: <app> — '<newTitle>' (ID <id>)` |

Interpolated strings (app names, titles) use the system log's default private redaction; integers are public. The window manager, accessibility-element helper and accessibility permission helper do not log, and observer creation or registration failures are not logged.

