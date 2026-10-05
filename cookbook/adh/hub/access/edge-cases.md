
- **Null and empty input — `workspace`**: Not checked client-side. `workspace` is a plain
  string the caller supplies; an empty slug is sent to the server unchanged as `workspace=`.
  A non-empty customer or org slug is a caller precondition, per the module's top-of-file
  comment.
- **Null and empty input — assignment scope pairing**: see `assignment-scope-pairing-passthrough`
  below.
- **Empty `grants` array**: the create-role and update-role operations MUST send an empty
  `grants: []` unchanged when the caller supplies one; no client-side check requires at
  least one grant — a role with zero grants is a valid, unvalidated request as far as this
  module is concerned.
- **Boundary values — grant verb strings**: grant rows' item-verb and subitem-verb fields are
  strings with a documented expected character set (a comma-letter subset of `C,R,U,D,M` and
  `C,R,U,D` respectively), but the create-role and update-role operations send whatever
  string the caller provides with no client-side charset or length check. This is a fact,
  not a gap: the sibling fallback-feature-list documentation notes that "every submitted
  grant is refined against it server-side," establishing that this client's job is to pass
  the value through, not police its shape.
- **Concurrent access — module state**: the client holds no shared mutable state between
  calls (the only persistent value is the read-only fallback feature list), so there is
  nothing for two concurrent calls to race on within this module.
- **Concurrent access — competing writes**: two concurrent assignment-upsert calls for the
  same subject and scope follow ordinary upsert semantics — last response received wins,
  with no client-side sequencing or optimistic-lock check in this file.
- **Error states — validation failure vs. HTTP failure**: the error `feature-row-shape-validated`
  throws and an HTTP error are distinguishable only via the shared status-extraction
  helper's status check.
- **Error states — 204 on a declared-void write**: see `item-restrict-restore-parse-body`
  above; this is the one place in the file where an operation declared to resolve with no
  value can throw on success-shaped input, depending on what the backend actually returns.
- **Offline or disconnected state**: none of the ten operations catches a network-level
  failure; a connectivity loss mid-call propagates unhandled out of the client to the
  caller, with no retry, queuing, or offline-specific handling anywhere in this file.
- **No timeout**: no call sets a deadline or cancellation signal; a reachable-but-unresponsive
  backend leaves the call pending until the underlying transport's own limit, if any.
- **No cancellation**: no operation accepts a cancellation-signal parameter, so a caller
  cannot cancel an in-flight request through this module.
- **No retry beyond the 401 waterfall**: every call issues exactly one request (plus, on a
  `401`, the single inherited refresh-and-retry); nothing in this file retries a network
  failure or a non-401 error status.
- **assignment-scope-pairing-passthrough**: the assignment write input's `feature` and `itemId`
  fields are independently optional, and the assignment-upsert operation MUST send whatever
  combination the caller passes verbatim; it performs no client-side check that the two are provided
  together (to scope a grant to one item) or omitted together (for a workspace-wide grant), even
  though the field's own doc comment declares that pairing.

