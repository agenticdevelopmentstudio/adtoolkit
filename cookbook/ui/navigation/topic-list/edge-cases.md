
- Null/empty input (MUST): An empty grouped setter call yields an empty
  row cache; the list shows zero rows and the selected-item query returns
  none. An item's icon and a section's title are both optional and handled
  per **render-item-without-icon-when-nil** and
  **omit-header-for-untitled-section**; an item's id/title are
  non-optional, so the type system rules out a missing value for them.
- Boundary values (MUST): With no sections, no title, no footer, and no
  header accessory, computing the preferred width returns exactly the
  fixed chrome padding (64pt) - the minimum value this computation can
  produce. Source imposes no maximum on section or item count; any array
  size is handled uniformly through the same row model.
- Duplicate item ids (SHOULD): Selecting by id resolves via a first-match
  lookup; if two items across sections share an id, only the row for the
  first match in list order is ever selected by this operation - source
  performs no uniqueness validation. Callers SHOULD supply unique ids
  across all sections passed to one grouped-setter call; this is
  undocumented in source and left to caller discipline. This SHOULD needs
  no separate test vector: the behavior described here is a direct,
  deterministic consequence of the same first-match lookup
  **select-item-by-id**'s vector (topic-list-012) already exercises, and
  a second, near-identical vector for the duplicate-id case would not
  exercise any additional code path.
- Concurrent access: Not applicable - the component confines all reads
  and writes of its section list, row cache, and selection-suppression
  counter to a single execution context (see Platform Notes for the exact
  confinement mechanism); source provides no path for two threads to
  mutate this component's state simultaneously.
- Error states: Not applicable - this component contains no throwing
  function, no result type, and no network or file-system call; the
  flat/grouped setters and selecting an item by id are synchronous,
  non-failing operations with no failure mode to represent beyond the
  silent no-ops already described above (missing id, already-selected
  id).
- Offline/disconnected: Not applicable - the component performs no
  networking anywhere in source; it only renders caller-supplied
  in-memory data.
- Header row reached via selected-item query (MUST): The selected-item
  query's guard returns none defensively if the current selection were
  ever a group header row; in practice this cannot occur because the
  selection-gating check already refuses to select header rows, but the
  accessor does not rely on that invariant holding elsewhere in the
  delegate chain.
- Nested selection-suppression scopes (MUST): The selection-suppression
  counter is an integer nesting counter, not a boolean, specifically so
  that a suppression scope nested inside another still leaves suppression
  active until the outer scope also exits; no call site in this component
  nests scopes today, but the suppression mechanism supports it without
  change if a future call site does.

