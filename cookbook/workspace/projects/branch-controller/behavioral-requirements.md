
- **checkout-ownership**: Branch management MUST hold exactly one checkout,
  one git status provider, and the mutable current branch for that
  checkout, and MUST NOT read or mutate any other checkout's state.
- **injected-dependencies-no-defaults**: Construction MUST require the
  checkout, the git client, and the git status provider as parameters with
  no default value for any of them, and MUST NOT construct a git client or
  git status provider internally — a provider minted internally could
  never be the one a checkout's panes were already given before the
  component exists, which would leave one checkout served by two status
  providers.
- **initial-branch-from-checkout**: Construction MUST set the current
  branch to the checkout's branch at construction time, before any call to
  refresh.
- **pane-identity-per-tab-per-edge**: Requesting a tab pane for a given
  edge and tab MUST return the same tab pane instance for every call made
  with the same edge and tab pair on one component, found by a scan of its
  known panes matching both edge and tab, and MUST reload that existing
  pane before returning it.
- **pane-created-once-per-tab-per-edge**: Requesting a tab pane for an edge
  and tab pair not already known MUST construct exactly one new tab pane
  for that edge and tab, and a different edge or a different tab MUST
  always be treated as a distinct pane.
- **pane-registration-on-creation**: A newly constructed pane MUST have
  both its data source and its context-menu provider set to the owning
  branch management component, MUST be added to the known panes, and MUST
  be reloaded before being returned.
- **weak-pane-table**: The known panes MUST be held weakly, so a pane
  released by every other owner MUST be dropped from the known panes
  without branch management ever calling an explicit unregister method.
- **display-name-derivation**: The display name MUST return the current
  branch when it is non-nil, and otherwise MUST return the last component
  of the checkout's directory path, computed fresh from the live current
  branch on every access rather than from any value captured when the
  component was built.
- **refresh-updates-branch-on-success**: When reading the current branch
  from git for the checkout's directory succeeds, refresh MUST assign that
  result to the current branch, including replacing a non-nil current
  branch with nothing when the checkout is now a detached HEAD.
- **refresh-preserves-branch-on-failure**: When reading the current branch
  fails, refresh MUST leave the current branch at its previous value; the
  error MUST NOT be rethrown, logged, or otherwise surfaced by this
  operation.
- **refresh-always-reloads-panes**: refresh MUST reload every known pane
  after its branch-read attempt, regardless of whether that attempt
  succeeded, failed, or there were no panes to reload.
- **commands-computed-per-access**: The commands MUST be computed fresh on
  every access as a list of exactly three commands — Refresh Status,
  Reveal in Finder, Copy Path, in that order — rather than cached from a
  previous access.
- **command-id-namespacing**: Every command id MUST be
  `branch.action.<verb>.<checkout-identifier>` (`refreshStatus`,
  `revealInFinder`, or `copyPath`), so that two checkouts — including two
  worktrees of the same repository — MUST NOT produce colliding command
  ids.
- **command-category-carries-checkout-name**: Every command's category
  MUST be `Branch — <display name>`, evaluated at the time the commands
  are read, so a palette listing commands from multiple checkouts MUST
  show each checkout's live name.
- **command-title-excludes-checkout-name**: A command's title (`Refresh
  Status`, `Reveal in Finder`, `Copy Path`) MUST NOT include the
  checkout's name or branch; the title is what a per-pane context menu
  renders alone, where the pane itself already identifies the checkout.
- **refresh-status-command-effect**: Invoking the Refresh Status command
  MUST trigger a status refresh without waiting for or otherwise observing
  its effect, and MUST separately begin an independent, asynchronous
  branch refresh that does not block the invoking call; each reference to the branch management component MUST NOT keep it alive beyond what that
  outstanding work needs.
- **reveal-in-finder-command-effect**: Invoking the Reveal in Finder
  command MUST reveal the checkout's directory in the system file browser,
  using the directory captured by value at the time the commands were
  read, not read again through live state at invocation time (see Platform
  Notes).
- **copy-path-command-effect**: Invoking the Copy Path command MUST
  replace the system clipboard's contents with the path of that same
  value-captured directory (see Platform Notes).
- **captured-directory-outlives-controller**: Because Reveal in Finder and
  Copy Path capture the directory by value rather than through live state,
  they MUST NOT fail or act on the wrong directory when invoked after the
  owning branch management component has been released or its commands
  unregistered — this is deliberate, so an unregister that races a menu
  already on screen still does the right thing rather than silently
  nothing.
- **data-source-agent-name-fixed**: Reading the pane's agent name MUST
  always return the literal string `Claude`, regardless of the pane or the
  checkout — a placeholder pending later work.
- **data-source-model-name-nil**: Reading the pane's model name MUST always
  return no value.
- **data-source-status-symbols-fixed**: Reading the pane's status symbols
  MUST always return a single idle symbol.
- **data-source-session-name-derivation**: Reading the pane's session name
  MUST return the display name.
- **data-source-working-directory-fixed**: Reading the pane's working
  directory MUST return the checkout's directory unchanged for the
  component's lifetime.
- **data-source-branch-passthrough**: Reading the pane's branch MUST
  return the live current branch.
- **data-source-summary-nil**: Reading the pane's summary MUST always
  return no value.
- **context-menu-built-from-commands**: Building the pane's context menu
  MUST create one menu item per command, in the same order, each titled
  with that command's title.
- **context-menu-run-discards-arguments-and-result**: Each menu item's
  action MUST invoke the corresponding command's run operation with an
  empty argument list and MUST discard the returned value.
- **context-menu-target-retention**: Each menu item MUST retain a strong,
  independent reference to its wrapped command for the item's whole
  lifetime, so the command keeps working even though nothing else in the
  application continues to hold it (see Platform Notes for the mechanism
  this needs on this platform).
- **context-menu-item-enablement-via-validation**: Each menu item's enabled
  state MUST be governed dynamically by the wrapped command's enabled state
  at the moment the menu is shown, and MUST NOT be fixed once when the menu
  item is built (see Platform Notes for the platform mechanism that
  provides this).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

