
This logic reads from and writes to no localization catalog; every hardcoded string below is a
plain English literal authored directly in this recipe's source, stated here as fact rather than
as a gap:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `Failed to load conversations` | The DM conversation list state's fallback `error` message when the rejected load's error has no message |
| — | `Failed to load messages` | The DM thread state's fallback `error` message when the history load rejects without an error instance |
| — | `Failed to load notifications` | The notification inbox state's fallback `error` message when the rejected fetch's error has no message |

Every other error message a caller can observe from this logic (a typed HTTP error's message, or
one produced by the shared request client's own `204`-body check) originates outside this recipe
and is not authored here.

