
- **Empty `configs` list**: MUST NOT be rejected at construction; the
  source has no non-empty check, and this is exactly the shape the
  missing-selection test decodes.
- **`selectedConfigId` is absent**: MUST be accepted as the documented
  zero-config path (see `selected-config-id-optional`); this is not an
  error state.
- **`selectedConfigId` does not match any `id` in `configs`**: MUST NOT be
  rejected at construction; this component enforces no referential
  relationship between the two fields. Downstream, the daemon provider
  resolver's selected-configuration lookup already tolerates exactly this
  case gracefully — returning none when no entry matches — and the
  daemon's chat-completion path falls through to the zero-config
  command-line default — so a dangling selection is a defined,
  non-crashing outcome once the payload reaches that resolver, even though
  this component itself does not validate it.
- **Duplicate identifier values across `configs` entries**: See
  `configs-id-uniqueness-unenforced` — this component accepts duplicates
  with no error, and what happens once such a payload is persisted is
  undefined in source.
- **Empty string identity or model fields** (name, plugin identifier,
  template identifier, model all empty strings): MUST NOT be rejected; the
  source performs no content validation on any text field.
- **Empty `values` or `secrets` maps**: MUST NOT be rejected; both are
  plain text-to-text maps with no minimum-count requirement.
- **The same field key present in both `values` and `secrets`**: this
  component enforces no disjointness between the two maps; nothing in
  this component resolves which one a receiver should prefer if both
  contain the same key.
- **Very large `configs` list**: MUST NOT be rejected; this component
  declares no upper bound on the number of configurations a sync payload
  may carry.
- **Concurrent access**: applicable, and safe by construction for reads —
  the sync envelope and resolved-configuration record are safe to share
  across concurrency domains, so an already-constructed, unshared copy
  MAY be read from multiple concurrent execution contexts with no
  synchronization. Because every stored field is mutable (see
  `mutable-stored-properties`), a single instance held in shared mutable
  storage still needs the caller's own synchronization (a confinement
  mechanism, a lock, or a serial queue) to avoid a data race on that
  shared variable — being safe to share guarantees a value is safe to
  *transfer*, not that a shared mutable binding to it is automatically
  synchronized.
- **Error states from a dependency**: Not applicable — this component has
  no dependency (no network, database, or file-system call) of its own
  that could fail; whatever eventually sends or receives this payload over
  the app-daemon boundary is a different, currently-unimplemented
  component (see `sync-application-unimplemented`), not this component.
- **Offline or disconnected state**: Not applicable — this component
  performs no network access itself; it only defines the shape of a
  payload some other, unimplemented transport would carry.
- **Cancellation and timeouts**: Not applicable — every operation in this
  component (construction, encoding, decoding, equality) is synchronous
  and non-suspending; there is nothing to cancel and no operation that can
  time out.

