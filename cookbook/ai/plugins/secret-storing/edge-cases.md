
- **Empty key ("")**: get, set, delete, and delete-legacy MUST NOT reject
  it; the production implementation's query construction treats it as an
  ordinary (if unusual) account identifier in the current service scope.
- **Empty value (set with "")**: set MUST succeed and store the empty
  string as a legitimate value, and a subsequent get for the same key MUST
  return an empty string, not none (see secret-storing-007); an empty
  stored value is distinct from an absent one.
- **Missing key**: get for a key never stored MUST return none; delete and
  delete-legacy for such a key MUST return success (see delete-idempotent,
  deletelegacy-idempotent).
- **Boundary — oversized value**: the interface and its production
  implementation impose no maximum length on value before delegating to the
  secure-storage helper; SHOULD the underlying secure store reject an
  oversized payload, set returns failure through the same not-successful
  path any other secure-storage failure takes — no length validation
  happens in this component before that point.
- **Concurrent access — same key**: see
  Behavioral Requirements (same-key-concurrent-mutation) and its Design Decision; concurrent
  set/delete calls targeting the *same* key have no documented ordering
  guarantee and can produce a spurious failure result or a transient
  false-negative read.
- **Concurrent access — delete-legacy's global service swap**: MUST be
  serialized by the caller with any other secure-storage-helper access (see
  deletelegacy-caller-serialization); the source documents this obligation
  but performs no internal locking to enforce it, so a caller that violates
  it races the shared active-service identifier — recorded as a design
  decision below, not as an unresolved gap, since the required ordering is
  stated explicitly by the source.
- **Error states — secure store unavailable or returns a non-success
  status**: the secure-storage helper's get/set log the failing status and
  return none/failure; the interface's get/set/delete propagate that
  none/failure verbatim with no distinct error type, retry, or additional
  detail — a caller cannot distinguish "no value was ever stored" from "the
  secure store rejected this specific read/write."
- **Offline or disconnected state**: Not applicable — this component makes
  no network call of any kind; the secure store is local to the device, so
  there is no connectivity-loss case to handle.

