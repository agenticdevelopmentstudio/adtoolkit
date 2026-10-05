
- Null/empty input: Resolving a descriptor for a view id with no entry
  MUST return the `unknown` descriptor rather than throwing or crashing
  (see **descriptor-default**).
- Null/empty input: Building content for a view id with no entry MUST
  return a placeholder rather than throwing (see **unregistered-fallback**).
- Null/empty input: Building content called with no tree id MUST fall back
  to the node id (see **tree-id-default**), rather than leaving it unset or
  generating a new identifier.
- Null/empty input: A placeholder pane loaded while the theme's
  chart-series color list is empty MUST leave the container untinted per
  **empty-series-no-tint**.
- Boundary values: A theme switch from a chart-series list that is
  non-empty to one that is empty MUST leave the container's previously set
  tint in place, per **stale-tint-persistence**.
- Boundary values: Unregistering the `placeholder` view id MUST always be
  refused, regardless of how many other view ids are registered — the only
  view id the registry hard-codes as non-removable.
- Boundary values: pane number 1 MUST index the first entry of the
  chart-series color list, and any pane number larger than the list's
  length MUST wrap via modulo rather than index out of bounds.
- Concurrent access: the registry and everything it constructs are
  confined to a single thread; registration, unregistration, lookup, and
  content creation all happen there, so concurrent mutation from multiple
  threads is not a case this file has to handle.
- Error states: The only error path in this file is an unregistered view
  id, and it is not surfaced as a thrown error or shown to the user — it
  is handled by falling back to a placeholder pane and logging an error
  (**unregistered-fallback**, **placeholder-protection**). Nothing in this
  file communicates that fallback to the caller beyond the placeholder
  itself and the log line.
- Offline/disconnected: Not applicable. The registry makes no network call
  and holds no server-backed state; it is a pure in-memory, single-process
  map from view id to descriptor and factory.

