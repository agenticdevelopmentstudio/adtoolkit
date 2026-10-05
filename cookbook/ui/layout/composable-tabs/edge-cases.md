
- Null/empty input (MUST): The list of children MAY legitimately be empty (a
  degenerate node mid-teardown); taking a snapshot then returns a placeholder
  leaf rather than trapping (see `snapshot-empty-tree-is-placeholder`). Every
  child's thickness fraction may be unset, and unset (never sized) is handled
  throughout by falling back to the descriptor's preferred thickness fraction
  or to an even split.
- Boundary values (MUST): Construction traps at a hard upper bound of 2
  children (`binary-or-solo-children`); the preferred-thickness loop over
  dividers degenerates to zero iterations for 0 or 1 children, so a
  solo-child split never attempts to place a divider that does not exist.
- Concurrent access: Not applicable — the type is confined to run on a single
  thread, and every mutating operation (split, remove, rebuild, move,
  capturing thickness fractions, the persistence debounce) reads and writes
  its children and its own stored state only there; source provides no path
  for two threads to mutate one instance simultaneously.
- Error states: see the named requirements **split-no-ops-without-project**
  (the project reference is held weakly, and a project that has already gone
  away makes a split return immediately with no mutation) and
  **move-permitted-without-spec** (a resolved project with no layout spec
  configured permits a move rather than refusing it). The layout-parent
  reference is also held weakly; finding the root's upward walk simply stops
  if that chain is broken, rather than throwing.
- Offline/disconnected: Not applicable — this component performs no
  networking; persistence is delegated entirely to the layout-change callback
  the host installs, and durability of whatever that callback does with the
  snapshot is outside this component's own concern.
- Zoom and minimize are mutually exclusive (MUST): requesting zoom restores a
  minimized pane before zooming it, and requesting minimize clears an
  existing zoom before pinning — a pane can be in at most one of the two
  states at a time.
- Refusing the tab's last pane with nowhere to send it (MUST): if the spec
  vetoes removing a tab's only pane and no last-pane-close handler is
  installed, requesting close announces a refusal and leaves the pane in
  place; the pane simply cannot be closed through this path.
- Idempotent persistence (MUST): comparing a rounded thickness signature
  against the last one written and skipping the layout-change callback
  entirely when nothing actually moved — a window resize that ends where it
  began, or a tab switch that re-triggers a layout pass, costs no write.
- A move the spec disallows leaves the tree untouched (MUST): moving
  computes the candidate tree before deciding, and returns `false` with zero
  mutation when the spec refuses it — there is no partial move to roll back.
- Rebuilding onto a shape with fewer leaves than were live (MUST): every
  previously-live leaf whose id does not survive into the new shape is
  notified of its removal before the new tree is constructed (see
  **rebuild-tears-down-dropped-panes**), so its process/watcher resources are
  released rather than merely dereferenced.

