
- Null/empty input: see **default-descriptor** — when no descriptor is
  supplied at construction, the component MUST construct a default
  descriptor, which in turn defaults its title to an empty string. This
  is a well-defined path, not an unhandled gap.
- Boundary values: Not applicable — this component takes no numeric or
  range-constrained input; the descriptor is a reference type with no
  bounds.
- Concurrent access: see **confines-to-ui-thread** (the Swift mechanism is in Platform Notes) — the
  component is confined to a single, serialized execution context, so
  every construction, read, and mutation is serialized; this component
  itself has no concurrency hazard.
- Error states: Not applicable — every operation in this component (view
  loading, both construction paths, the add-group method, the hosting
  helper) is synchronous and non-throwing; no error or completion-with-
  error path appears anywhere in source.
- Offline/disconnected: Not applicable — this component performs no
  networking; it touches only in-process UI state.
- Oversized hosted content: see Design Decisions for why the hosting
  helper preserves only a sizing preference on the wrapper it returns.
  Content taller than the detail pane is not clipped or resized by this
  component; the scrolling container that hosts a panel (outside this
  component) reads that preference to decide whether to scroll. This
  component's own guarantee is limited to advertising a sizing
  preference, not a hard constraint — it does not itself scroll or clip
  oversized content.

