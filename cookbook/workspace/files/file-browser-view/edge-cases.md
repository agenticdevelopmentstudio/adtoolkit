
- **Null/empty input**: Invoking the add-directory action and confirming the
  picker with zero locations selected is not reachable through the picker
  (it requires at least one choice to confirm); the browsed roots are
  unaffected in that case. Invoking the remove-directory action with no
  selection MUST refuse via refusal feedback (see
  `remove-directory-requires-selected-root`).
- **Boundary values**: Selecting many directories at once in the picker
  MUST add every one not already present, in the order the picker returns
  them (per `add-directory-preserves-panel-order`), and MUST select only the
  last one (per `add-directory-selects-last-added`) even when several are
  added in a single call.
- **Concurrent access**: Changes to the additional roots are observed and
  applied on the component's own execution context before triggering a
  manager rebuild, and the directories/selection state is confined to that
  same context (see Platform Notes for the mechanism used on Apple
  platforms). Multiple browser panes of the same project can share one
  directories/selection/restoration state; when one pane adds or removes a
  root, every other pane observing the same state rebuilds its own managers
  and clears any of its own selection state that pointed under the removed
  root (`teardown-clears-orphaned-node-selection`,
  `teardown-clears-orphaned-root-selection`). This is stated as
  `multi-pane-consistency`, a SHOULD-level guarantee for multi-pane hosts:
  it is documented as the reason those two clears exist, but no explicit
  test in the given source exercises two live components at once.
- **Error states**: The picker being dismissed without a choice is treated
  as a no-op, not an error — no dialog is shown. A directory the user
  already added is likewise treated as a no-op, not an error. Removing a
  non-removable or unselected root produces refusal feedback (an audible
  cue, by default), not a modal error. If the injected git status
  provider's repository root fails to match a new root, the component does
  not raise an error; it simply omits the provider
  (`git-status-provider-reuse`), leaving whatever the manager does with no
  provider (constructing its own) out of this component's scope.
- **Offline/disconnected state**: Not applicable. This component reads and
  watches the local filesystem only; it makes no network requests, so there
  is no connectivity-loss behavior to define here. (Git status refreshes are
  the concern of the injected/constructed git status provider, a separate
  component.)

