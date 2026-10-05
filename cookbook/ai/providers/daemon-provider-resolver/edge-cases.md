
- **Null/empty input**: settings returning none for every key (e.g. a
  fresh install with no configuration ever synced) MUST cause the
  configurations lookup to return an empty list, the selected-configuration
  lookup to return none, and the model lookup to return an empty string —
  never crash or raise an error (MUST).
- **Null/empty input**: settings returning an empty string for the
  configurations key MUST be treated identically to none (both fail the
  non-empty check), yielding an empty list (MUST).
- **Null/empty input**: settings returning an empty string for the
  selected-configuration-id key MUST be treated identically to none (both
  fail the non-empty check), yielding none from the selected-configuration
  lookup (MUST).
- **Boundary values**: a registry value of "[]" (a valid, well-formed
  empty JSON array) at the configurations key MUST decode to an empty list
  via the success path, not the malformed-input path — a successful decode
  of zero elements, distinct from an absent or malformed value that also
  yields an empty list (MUST).
- **Boundary values**: a registry with exactly one configuration whose
  identifier matches the selected-configuration-id key is the minimum
  non-empty case for the selected-configuration lookup to succeed; it MUST
  return that configuration (MUST).
- **Boundary values**: the model lookup places no length or character
  constraint on the returned string; whatever value is stored at a
  configuration's model key — including a very long string, one containing
  non-ASCII characters, or one that names no model the plugin actually
  recognizes — MUST be returned verbatim (MUST).
- **Concurrent access**: applicable. The resolver holds no stored or
  shared mutable state and declares no confinement to a single execution
  context, so calls from multiple concurrent execution contexts MUST NOT
  require a lock, queue hop, or suspension, and MUST NOT race, because each
  call only reads through the caller-supplied, concurrency-safe settings
  function (MUST).
- **Concurrent access**: the selected-configuration lookup performs two
  independent reads through the settings function — once directly for the
  selected-configuration-id key, once indirectly via the configurations
  lookup for the configurations key. If the underlying store is mutated
  between those two reads by a concurrent writer, the two values are not
  read as one atomic snapshot; a transient none result MAY occur and MUST
  be tolerated as equivalent to "not currently resolvable," never treated
  as an error (MUST).
- **Error states**: the only dependency is the caller-supplied settings
  function. The resolver MUST treat any none return from settings as "key
  absent" and MUST NOT distinguish "key never set" from "underlying store
  unavailable" — both surface identically, because the settings-reader's
  shape carries no error case (MUST).
- **Error states**: a configurations-key value that is present, non-empty,
  and syntactically valid JSON but decodes to the wrong shape (e.g. a JSON
  object instead of an array) MUST be swallowed and yield an empty list,
  identically to syntactically invalid JSON (MUST).
- **Offline or disconnected state**: Not applicable — the resolver makes
  no network call and has no notion of connectivity; whether the
  app-daemon sync that originally populated the settings store is
  currently reachable is a concern of that separate component, not of this
  read-only lookup.
- **Cancellation and timeouts**: Not applicable — every operation is
  synchronous and non-suspending; there is no operation to cancel and
  nothing that can time out.
- **Missing file or unreachable server**: Not applicable — the resolver
  opens no file and calls no server; it only invokes the passed-in
  function, whose own failure modes are outside this component's contract.

