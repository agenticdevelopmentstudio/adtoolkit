
- **Data collected**: this recipe does not originate personal data of its own; it reads and writes
  message content (the message body field), notification records (including an arbitrary
  key-value payload and an optional actor id), and presence facts (`online`, `lastSeenAt`) for the
  ids the caller supplies.
- **Storage**: none held by this logic beyond in-memory state for the lifetime of the mounted
  component; nothing is written to persistent browser storage, a database, or a file by this
  logic.
- **Transmission**: yes, on every call. Plain HTTP calls carry the bearer credential in the
  `Authorization` header via the shared authenticated request client; the two live connections
  instead carry that same credential as an `access_token` URL query parameter, per
  `sse-token-rides-the-query-string` — a distinct exposure surface (URLs can reach server access
  logs, browser history, and intermediate proxies in ways a header does not) that this recipe
  records as a documented fact, not a change it makes.
- **Retention**: none retained by this logic after the response or event it produced is applied to
  state; whatever the backend itself retains is outside the scope of this recipe.

