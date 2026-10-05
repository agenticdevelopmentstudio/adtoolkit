
- **Unfilled path parameter**: path substitution leaves an unmatched `{name}`
  segment visible, unencoded, in the built path rather than erroring or
  omitting the segment — a deliberate, documented rendering choice, not a
  gap.
- **Cyclic schema**: example derivation's "seen"-set threading guarantees
  termination on a schema that refs itself directly or transitively.
- **Slug collision**: two endpoints that would project to the same slug cause
  the lazily-built slug index to throw at build time rather than silently
  aliasing one endpoint's reference page onto another's.
- **External (non-local) reference**: reference resolution only resolves
  local schema-component references; a schema containing a reference outside
  that scope is not resolved and falls through example derivation's
  remaining precedence steps (this API's generated schemas are self-contained,
  so this scope limitation is a design decision — see Design Decisions — not
  a runtime failure mode).
- **Out-of-order network responses**: the CRUD resource state's sequence-number
  guard is the specified defense against a slow list response overwriting a
  newer one; a mutation (create/update/remove) has no equivalent sequence
  guard because those calls are not re-issued concurrently against the same
  resource by the state itself.
- **Concurrent access to the editability overrides**: this overrides object is
  empty by default and is intended as static, hand-populated configuration;
  production code never mutates it at runtime. Only test code mutates and
  restores it. Because the runtime is single-threaded, this is not a
  concurrency hazard in practice — it is a fact about the module's intended
  use, not an unresolved gap.
- **Network-level failure of a built request**: an offline/DNS/cross-origin
  failure rejects the request executor's promise instead of producing a
  normalized result (see network-failure-propagation); the caller turns it
  into an error message.
- **Hung request**: no timeout or cancellation bounds the request built by the
  request builder/executor (see request-timeout); a connection that never
  resolves keeps the request in flight.

