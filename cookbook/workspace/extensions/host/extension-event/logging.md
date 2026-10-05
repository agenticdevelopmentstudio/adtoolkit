
Subsystem: the app's bundle identifier (falling back to a placeholder when unavailable) | Category: derived from this component's type name

| Event | Level | Message |
|-------|-------|---------|
| The map function returns nothing for a registration's context during delivery | error | `<path> could not build its event value in context '<context name>'; this listener is skipped` |
| A listener throws during delivery | error | `A <path> listener threw: <exception description or "<unprintable>">` |
| A listener's context cannot dispatch during delivery | error | `A <path> listener could not be invoked: <unavailability message>` |

No other event in this file is logged: subscribing's two refusals (non-function listener, disposable-creation failure) are surfaced to the extension as thrown/raised errors instead of being logged, per **subscribe-rejects-non-function-listener** and **disposable-creation-failure-rolls-back**.

