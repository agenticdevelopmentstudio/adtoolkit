
Subsystem: the app's bundle identifier (falls back to the literal string `nil` if absent) | Category: the conforming provider's role name (e.g. the secure persistent provider, the embedded-database provider)

| Event | Level | Message |
|-------|-------|---------|
| Secure-store non-string encode failure | error | Failed to encode value for secure key, naming the key |
| Embedded-database encode failure | error | Failed to encode value for key, naming the key |
| Embedded-database `SELECT` prepare failure | error | prepare SELECT failed, with the underlying error message |
| Embedded-database `UPSERT` prepare failure | error | prepare UPSERT failed, with the underlying error message |
| Embedded-database blob bind failure | error | bind blob failed, with the underlying error message |
| Embedded-database `UPSERT` step failure | error | UPSERT step failed, with the underlying error message |

The in-memory provider, in-memory secure provider, plain persistent provider, and cloud-synced provider emit no log lines in the given sources.

