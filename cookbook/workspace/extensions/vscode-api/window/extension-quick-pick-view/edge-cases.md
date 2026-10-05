
- **Null/empty input — no items**: `model.request.items = []`. `visibleIndices`
  is empty, `highlightedIndex` is nil, the table shows zero rows, and
  invoking the accept action (Return) is a no-op because
  `acceptedIndices()` returns nil in single-select — computed entirely by
  the model, with no additional guard in this component.
- **Boundary values — all-separator list**: Every item in
  `model.request.items` is a separator. `highlightedIndex` stays nil (no
  selectable row exists), arrow keys and clicks are no-ops throughout, and
  the accept action never fires `onAccept` in single-select — traceable
  directly to the model's own `firstSelectableIndex` returning nil.
- **Boundary values — separator with no surviving section**: A filter
  query that matches nothing in a section hides that section's separator
  along with its items. This is the model's own filtering
  rule, not this component's; see the second entry under **Design
  Decisions** for why it exists.
- **Concurrent access**: Not applicable — the component serializes every
  access to its state onto a single, consistent execution context; there
  is no code path by which two threads can mutate the component or its
  model simultaneously.
- **Error states**: Not applicable — every operation in this component
  (query updates, highlight moves, row clicks, table reloads) is a
  synchronous operation that cannot fail; no error-producing path exists
  in this component.
- **Offline/disconnected**: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  model built from a request handed to it at construction.
- **Historical defect, now guarded — separator click accepting a stale
  highlight**: See **Design Decisions** (the guard against accepting a
  stale highlight on a separator/out-of-range click) and
  **separator-and-out-of-range-clicks**; the guard is shared by both the
  single- and multi-select branches so this cannot regress silently.
- **Multi-select empty acceptance**: A user can press Return in
  multi-select with zero rows checked. `acceptedIndices()` returns `[]`
  (not nil), and the accept action calls `onAccept([])` — a real,
  reportable answer, not a dismissal. Callers MUST distinguish an empty
  array (`onAccept([])`) from a dismissal (`onCancel()`) — see
  **empty-choose**.

