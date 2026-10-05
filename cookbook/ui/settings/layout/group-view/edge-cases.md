
- Null/empty input: `title` (string, for title-based construction) and
  `header` (view, for header-view-based construction) are required,
  non-optional constructor parameters; the type system rules out a missing
  value for either (MUST — the initializer needs no nil-handling path
  because neither parameter can be absent).
- Empty `title` string (`""`): `header-from-title` still runs
  unconditionally, constructing a header whose label renders empty; the
  caption band and its 6pt spacing from the card remain in layout regardless
  (MUST, per `header-from-title` and `header-card-spacing` — there is no
  guard against an empty string).
- Boundary values: Not applicable — the component's only numeric behavior
  comes from its own fixed layout constants (10pt corner radius, 6pt
  caption spacing, 14pt horizontal inset, 9pt vertical inset, 1pt divider
  thickness); it exposes no caller-configurable numeric range of its own.
- Concurrent access: Not applicable — the component is confined to the UI
  thread (see `confines-to-ui-thread`), so adding a row, updating
  separators, and every layout change are serialized on that thread.
- Error states: Not applicable — every operation in this component (adding
  a row, updating separators, syncing visibility) is a synchronous,
  non-failing call; no error-producing path exists.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own.
- Zero rows added: the row area is pinned to the card's edges, so with no
  rows the card's size is exactly the row area's size; nothing in this
  component enforces a nonzero row count or a minimum card height, so an
  unpopulated group renders as an empty rounded, elevated-surface strip
  beneath its caption (MUST, per `row-area-edge-pinning` — no
  minimum-height constraint exists anywhere in this component).
- All rows hidden simultaneously: the layout omits space for hidden rows,
  and separator recomputation only ever toggles a row's own separator
  visibility on rows still present — nothing in this component ever hides
  the card itself. The card remains present, still painted with its
  elevated-surface fill and rounded corners (see `card-surface`), collapsed
  to near-zero height, rather than disappearing. Whether a fully collapsed
  card should hide itself is an open decision this component does not
  make — see Design Decisions.
- Passing the same content view instance to the row-add operation twice:
  Precondition — callers MUST NOT add the same view instance to the group
  more than once. Adding a view to a new parent typically detaches it from
  its previous parent first, so a second call wrapping the same instance in
  a new row silently removes it from the first row, leaving that row's own
  content constraints referencing a view no longer inside its subtree — the
  layout system then has no common ancestor left to satisfy them. This
  component contains no guard against this; honoring the precondition is
  the caller's responsibility, not a behavior `row-append` is required to
  produce.
- Moving the component between two different parents: `superview-width-
  match` activates a fresh width-match constraint on every attach to a
  parent, without deactivating any constraint created for a previous
  parent. Re-parenting the same component instance leaves both width
  constraints active simultaneously, which conflicts if the two parents'
  widths ever differ (MUST-level consequence of source; this component
  never stores or deactivates a previously created width constraint — see
  Design Decisions).

