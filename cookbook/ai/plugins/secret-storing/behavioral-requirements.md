
- **concurrent-share-safety**: The secret-store interface MUST require
  every conforming implementation to be safe to share across concurrent
  execution contexts, so a single store instance MAY be captured and
  invoked from any concurrency domain — the daemon's chat-completion
  operation captures its injected store inside asynchronous completion
  work.
- **get-contract**: get MUST return the value currently stored for key, and
  MUST return none when no value is stored for that key.
- **set-overwrites**: set MUST store value under key, overwriting — never
  appending to, merging with, or rejecting — any value already stored under
  that key.
- **return-value-optional**: set, delete, and delete-legacy MUST each allow
  their returned success value to be ignored by a caller without a warning
  or diagnostic.
- **delete-idempotent**: delete MUST return success both when it removes an
  existing value for key and when no value was stored for key; the absence
  of a value MUST NOT be reported as a failure, per the operation's own
  documented contract: "Idempotent — deleting an absent key is not an
  error."
- **key-value-opacity**: the secret-store interface MUST treat key and
  value as opaque caller-supplied strings, imposing no format, length, or
  character-set restriction of its own, per the documented contract: "The
  secret-storage abstraction is a separate concern from key naming — hosts
  bring their own key convention."
- **production-store-delegation**: the production implementation's get,
  set, and delete operations MUST delegate verbatim, in a single
  expression, to the secure-storage helper's corresponding get/set/delete
  operations, applying no additional transformation, validation, or caching
  of their own.
- **production-store-stateless**: the production implementation MUST hold
  no instance-stored property; every operation MUST read or mutate the
  secure-storage helper's process-wide shared state rather than any
  per-instance state, so every instance of the production implementation
  behaves identically to every other.
- **production-store-init**: the production implementation MUST expose a
  public, synchronous, non-failing, zero-argument way to construct an
  instance.
- **legacy-service-constant**: the production implementation's
  legacy-service identifier MUST equal the fixed literal
  "com.agentictoolkit", mirroring the secure-storage helper's own default
  fallback service identifier.
- **deletelegacy-targets-legacy-service**: delete-legacy MUST remove the
  entry stored under the legacy-service identifier for key, and MUST NOT
  remove or read any entry stored under the currently active service
  identifier.
- **deletelegacy-restores-pinned-service**: delete-legacy MUST restore the
  active service identifier to the value it held immediately before the
  call, before returning, regardless of whether the underlying delete found
  an entry.
- **deletelegacy-idempotent**: delete-legacy MUST return success when no
  entry exists under the legacy service for key, for the same reason
  delete-idempotent holds: it delegates to the same underlying delete
  operation, whose status check already treats "not found" as success.
- **deletelegacy-caller-serialization**: because delete-legacy retargets
  the shared, process-wide active-service identifier for the duration of
  the call, a caller MUST serialize every invocation of delete-legacy with
  any other concurrent access to the secure-storage helper — through this
  or any other secret-store instance — since neither the interface nor the
  production implementation performs any internal locking of its own; this
  obligation is stated directly by the operation's own documented contract:
  "Callers must serialize this with their other [secure-storage] access...
  so no concurrent access races the swap."
- **interface-over-concrete-usage**: a caller SHOULD depend on the abstract
  secret-store interface rather than the concrete production implementation,
  so a test double can be substituted without touching the real secure
  store — see Design Decisions for the rationale and the one production
  call site (the daemon's chat-completion operation) that follows it.
- **same-key-concurrent-mutation**: When two concurrent calls target set for the same key (or a concurrent set/delete pair on the same key), the outcome is unspecified: the production implementation's underlying write path performs a plain delete followed by a fresh add with no lock or compare-and-swap, so a losing writer's add can fail (making that set call return failure for otherwise well-formed input) or a concurrent get on the same key can observe a transient false negative between the internal delete and the re-add. Neither the interface nor the production implementation states an ordering guarantee for concurrent same-key access (contrast with delete-legacy, whose serialization requirement is documented explicitly).

