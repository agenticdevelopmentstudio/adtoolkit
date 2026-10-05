
Subsystem: the host application's own bundle identifier (falling back to a default when unavailable) | Category: a name derived from this component's own type name, per the shared logging convention's defaults

| Event | Level | Message |
|-------|-------|---------|
| `diagnosticsChanged(for:)` is called | debug | `diagnostics changed for \(uris.count) uri(s)` |

No other event in this component is logged: `diagnosticsChanged(for:)` has exactly one statement before firing the emitter, and it is this one.

