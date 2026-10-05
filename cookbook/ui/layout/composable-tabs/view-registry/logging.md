
Subsystem: the app's bundle identifier | Category: this component's own name

| Event | Level | Message |
|-------|-------|---------|
| Unregistering the `placeholder` view id | error | `Refusing to unregister {viewID} — every registry resolves it` |
| Building content for an unregistered view id | error | `No view registered for {viewID} — showing a placeholder` |

Both messages interpolate the view id's raw value, logged as public data.

