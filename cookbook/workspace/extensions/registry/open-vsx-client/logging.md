
Subsystem: `Bundle.main.bundleIdentifier` (via `Loggable`'s default) |
Category: `OpenVSXClient`

| Event | Level | Message |
|-------|-------|---------|
| — | — | Not emitted: `OpenVSXClient` conforms to `Loggable` and declares a static logger readable from any execution context, but no method in the source calls `logger` — every failure is communicated to the caller as a thrown `OpenVSXError` case instead of a log line. |

