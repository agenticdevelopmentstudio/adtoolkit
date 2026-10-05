
This module emits a single error-level log line with a literal `[alerts]` string prefix, not a structured logger with its own subsystem/category object.

| Event | Level | Message |
|-------|-------|---------|
| Webhook delivery failure (network error or 5,000ms abort) | error | `[alerts] webhook delivery failed (<n> alerts): <error message>` |

This is the only log line this module emits — a successful flush produces no log output at all, at any level.

