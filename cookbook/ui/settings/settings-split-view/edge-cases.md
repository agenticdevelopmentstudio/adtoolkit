
- **Null/empty input**: Replacing the panel list with `[]` and clearing
  the panel list both leave the stored panels empty, the sidebar empty,
  and the detail pane empty (MUST). Constructing with no panel-list
  argument uses a stock panel list rather than requiring a caller-supplied
  one (MUST).
- **Boundary values**: Selecting a panel by index and navigating to an
  index both guard against out-of-bounds access and are silent no-ops out
  of range (MUST). Moving the selection by a step stops at the first or
  last *visible* row rather than wrapping, and is a no-op when no rows are
  visible (MUST, see **steps-through-visible-rows-only**). A
  content-sized sidebar's width is capped at `480`pt regardless of how
  wide the panel list's preferred width reports (MUST, see
  **caps-content-sized-sidebar-width**).
- **Concurrent access**: Not applicable — the component's construction and
  every property access are confined to a single, serialized execution
  context (see Platform Notes), so there is no concurrent-access surface
  for this component to define behavior for.
- **Error states**: Not applicable — every member in this component is
  synchronous and non-throwing; there is no dependency, network call, or
  fallible operation in this component.
- **Offline/disconnected state**: Not applicable — this component performs
  no networking and has no dependency on connectivity.
- **Removing a panel not in the panel list**: The removal step removes
  nothing, but the operation still unconditionally resets navigation
  history, re-sets the sidebar's panel list, and invokes the
  navigation-change notification — the same side effects as a real
  removal. This is a documented observation of the component's actual
  behavior, not a deliberate contract (see split-view-controller-053).
- **Sidebar persistence key set to none while the content-sized-sidebar
  flag is `false`**: A subtype MAY override the sidebar persistence key
  to return none. In that case no persistence key is set, which silently
  disables width-persistence for that instance — no fallback name is
  substituted and nothing fails (see split-view-controller-024b).
- **Stale nested-detail floor after a nested split is removed**: The
  sidebar-unification step only recomputes the nested-detail floor when
  at least two nested settings-split-view panels remain; when a removal
  or a panel-list replacement drops the nested count from two-or-more to
  one or zero, this early exit leaves the nested-detail floor at its
  previous, now-stale value rather than resetting it toward `0`. The
  detail pane's floor can therefore stay wider than the current panel set
  requires until a later state again has two or more nested siblings.
  This is the component's actual, undocumented behavior — see Design
  Decisions and split-view-controller-054.
- **Toggling search-enabled or sort-by-title after their first effect has
  already run**: Neither setting reacts to a later change on its own.
  Search-enabled is read only once, during the view's load step, to
  decide whether to install the header accessory view — flipping it
  afterward has no further effect on an already-loaded view. Sort-by-title
  is read only inside the replace/add operations — flipping it does not
  retroactively reorder a panel list already installed; it only changes
  the outcome of the next mutating call.

