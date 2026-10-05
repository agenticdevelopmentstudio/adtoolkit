
Subsystem: the host app's bundle identifier, or "nil" when unset | Category: the reporting component (rule testing, the window matcher)

| Event | Level | Message |
|-------|-------|---------|
| Rule regex fails to compile while testing a title | error | `Invalid custom-rule regex '<pattern>': <reason>` |
| Fingerprint regex fails to compile while scoring | error | `Invalid title regex '<pattern>': <reason>` |

The rule store and the heuristic registry do not log; store errors are thrown to the caller.

