
Subsystem: the app's bundle identifier, or an empty/unset value when none is
configured | Category: the store's logging category name

| Event | Level | Message |
|-------|-------|---------|
| A listed document row has an unreadable timestamp | error | Names the marker table and the underlying parse error, both marked public for the system log |

The store's logger is spelled out directly through the platform's own logging type
rather than a shared logging protocol, because this target does not link the
framework that protocol lives in.

