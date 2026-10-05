
Construction options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `material` | `Material` | platform's hud-style default | Backdrop blur material, set once at construction and never reassigned afterward |
| `onDismissed` | `(() -> Void)?` | `nil` | Invoked synchronously once dismissal begins, before the fade-out animation completes |
| `isDismissing` | `Bool` | `false` | Readable by any caller, but settable only internally by the dismiss operation; `true` from the first dismissal call onward |

Beyond construction, the component exposes: a fixed fade duration
(`fadeDuration`, 0.2 seconds) and a fixed three-value set of dismiss keys
(`dismissKeyCodes`) shared by every instance and subclass; an operation to
present the overlay in a host view; an operation to dismiss it; and an
overridable pre-dismissal hook.

`fadeDuration` and `dismissKeyCodes` are fixed constants, not per-instance
options — they cannot be overridden by a subclass, so every instance and
subclass shares exactly the same 0.2 second fade and the same three dismiss
keys (Escape, Return, keypad Enter).

