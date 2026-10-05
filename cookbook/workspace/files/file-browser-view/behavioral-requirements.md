
- **tree-divider-footer-layout**: The component MUST arrange, top to
  bottom, the file tree, a one-point separator, and the add/remove footer,
  each pinned to the container's leading and trailing edges, filling the
  container's bounds.
- **window-background-fill**: The component MUST fill its root
  container with the window-background theme role.
- **footer-surface-fill**: The component MUST fill the footer strip with the
  surface theme role.
- **one-manager-per-root**: The component MUST maintain exactly one
  file tree manager for every root currently among the browsed roots.
- **primary-root-always-managed**: Looking up the primary root's manager MUST
  always resolve to a valid file tree manager; this invariant MUST hold for
  the lifetime of the component (enforced by failing immediately if it is
  ever violated, rather than silently constructing a throwaway manager).
- **start-watching-on-appear**: The component MUST start filesystem watching
  on every current manager when the component appears, if watching is not
  already active.
- **stop-watching-on-disappear**: The component MUST stop filesystem watching
  on every manager when the component disappears.
- **stop-watching-on-pane-teardown**: The component MUST stop filesystem
  watching on every manager when its pane content is about to be discarded,
  independent of whether the disappearance event has fired.
- **load-initial-once**: The component MUST perform the initial load on every
  manager exactly once — the first time the component appears — and MUST NOT
  perform it again on a later appearance of the same component.
- **add-directory-opens-panel**: Invoking the add-directory action MUST
  present a system directory picker configured to choose one or more
  directories and no files.
- **add-directory-cancel-noop**: If the picker is dismissed without a
  choice, the component MUST NOT change the browsed roots.
- **add-directory-skips-duplicates**: If a chosen directory is already one of
  the browsed roots, the component MUST leave the browsed roots unchanged for
  that directory and MUST NOT present an error.
- **add-directory-selects-last-added**: After adding one or more chosen
  directories, if the last chosen directory is a removable root (i.e. it is
  now one of the additional roots), the component MUST set the selected root
  to that directory.
- **add-directory-preserves-panel-order**: When the add-directory action adds
  more than one chosen directory from a single picker response, the component
  MUST add each one not already present among the browsed roots, in the same
  order the picker returned them.
- **remove-directory-requires-selected-root**: Invoking the remove-directory
  action while no root is selected MUST trigger refusal feedback and MUST NOT
  change the browsed roots or the selection.
- **remove-directory-requires-removable-root**: Invoking the remove-directory
  action while the selected root is not one of the additional roots (i.e. it
  is the primary root or already gone) MUST trigger refusal feedback and MUST
  NOT change the browsed roots or the selection.
- **remove-directory-clears-selection**: After a removal succeeds for the
  selected root, the component MUST clear the selected root to none.
- **remove-button-enablement**: The remove control MUST be enabled only while
  the selected root is a removable root, and MUST be disabled at every other
  time (no root selected, or the selected root is the primary or an
  already-removed root).
- **remove-button-tooltip**: While the remove control is enabled, its tooltip
  MUST read `Remove "<name>" from this project`, where `<name>` is the
  selected root's last path component; while disabled, its tooltip MUST read
  `Select an added directory to remove it`.
- **footer-buttons-identified**: The add control MUST carry the accessibility
  identifier `file-browser.add-directory` and the remove control MUST carry
  `file-browser.remove-directory`.
- **teardown-clears-orphaned-node-selection**: When a root is dropped from
  the browsed roots across a rebuild, the component MUST clear the selected
  node to none if the selected node's location lies at or under that root's
  path.
- **teardown-clears-orphaned-root-selection**: When a root is dropped from
  the browsed roots across a rebuild, the component MUST clear the selected
  root to none if it equals that root.
- **multi-pane-consistency**: When multiple browser panes share the same
  directories/selection/restoration state and one pane adds or removes a
  root, every other pane observing that shared state SHOULD rebuild its own
  managers and clear any of its own selection state that pointed under the
  added/removed root (see **teardown-clears-orphaned-node-selection** and
  **teardown-clears-orphaned-root-selection**).
- **late-added-root-loads-if-visible**: A manager created for a root added
  after the browser's own initial load has completed MUST have its initial
  load performed as part of the same rebuild.
- **late-added-root-watches-if-visible**: A manager created for a root added
  while the browser is currently watching MUST have watching started on it
  as part of the same rebuild.
- **git-status-provider-reuse**: When constructing a manager for a root, the
  component MUST pass the injected git status provider to that manager only
  when the provider's repository root, resolved by following symlinks,
  equals the new root resolved the same way; otherwise it MUST pass none.
- **open-request-forwarding**: Reading or writing the component's
  open-request callback MUST read or write the hosted tree's own
  open-request callback directly — there MUST NOT be a second, independent
  copy of this callback.
- **reveal-forwarding**: Revealing a node, and revealing nothing, MUST
  delegate directly to the hosted tree's own reveal operations.
- **pane-selection-change-notification**: The component MUST call the
  pane-selection-change callback whenever the selected node changes to a
  value different from its immediately preceding value, MUST NOT call it for
  the value already held at the time the observer was installed, and MUST
  NOT call it when the selected node is set to the value it already holds.
- **pane-selection-description**: The pane's selection description MUST
  return the selected node's name (not its path), or none when nothing is
  selected.
- **reuse-managers-across-rebuild**: When rebuilding the manager list, the
  component SHOULD reuse the existing file tree manager instance for any root
  that is still present among the browsed roots, rather than discarding and
  recreating it.
- **single-root-convenience-init**: The component MAY be constructed with a
  single-root convenience form, which builds the directories state with that
  location as the sole primary root and no additional roots.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

