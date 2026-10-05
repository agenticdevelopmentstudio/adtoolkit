
- **Empty field name**: the field-key operation MUST NOT reject an empty
  field name; it returns `"aiplugin.config.<id>.field."` with a trailing
  separator and no error, because this component performs no content check
  on the field name.
- **Whitespace-only or `.`-containing field name**: the field-key
  operation MUST NOT reject or alter such input; the string is interpolated
  verbatim (see `field-character-permissiveness`).
- **Field name containing `\n`**: See `field-name-newline-safety`. The key itself is still produced without
  error, but a caller that also maintains the fields-key/secret-fields-key
  ledger for that configuration will corrupt the ledger's newline-delimited
  parsing.
- **Two different configuration identifiers, same field name**: MUST
  produce two different keys for every one of the field-key, model-key,
  secret-fields-key, and fields-key operations (see
  `key-namespace-isolation`); two distinct configuration identifiers never
  share the same canonical string form, so no collision is possible.
- **Repeated calls with identical arguments**: MUST return the identical
  string every time (see `pure-computation`); there is no cache to
  invalidate and no counter or clock involved.
- **Concurrent calls**: applicable and safe by construction — this
  component holds no stored or shared mutable state, so calls from the
  app's main execution context and the daemon's own concurrency domain MUST
  NOT require any lock, queue hop, or suspension (see
  `concurrency-isolation`).
- **Boundary values on the configuration identifier**: none apply beyond
  what the identifier type itself enforces; every valid identifier value
  (including a randomly generated one and a fixed literal like the test
  fixture's) produces a well-formed 36-character canonical string, so there
  is no minimum/maximum or malformed-identifier case to handle — the type
  system rules it out before this code runs.
- **Error states from a dependency**: Not applicable — this component has
  no dependency (no network, database, or file-system call) that could
  fail; it never touches a store, only names one.
- **Offline or disconnected state**: Not applicable — this component
  performs no network access of its own; whether the daemon or app can
  currently be reached is a concern of whatever settings-reader/secret-store
  call site uses the returned key, not of this component.
- **Cancellation and timeouts**: Not applicable — every operation is
  synchronous, non-suspending, and infallible; there is nothing to cancel
  and no operation that can time out.
- **Missing file or unreachable server**: Not applicable — this component
  opens no file and makes no server call; a missing settings row or an
  unreadable credential-store entry at the key this component returns is
  the caller's failure mode, not this component's.

