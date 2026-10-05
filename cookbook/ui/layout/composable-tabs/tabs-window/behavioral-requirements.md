
- **window-id**: The window's identifier MUST be derived from the project's
  repository id, formatted as `"projectWindow.<repo-uuid>"`, so window
  geometry is persisted per project rather than per window type.
- **default-geometry**: With no saved frame for the project, the window MUST
  open at 800×500 points.
- **minimum-size**: The window MUST NOT be resized below 400×300 points.
- **frame-persistence**: The window's frame MUST be saved on move/resize and
  restored the next time a window for the same project id is shown.
- **standard-window-controls**: The window MUST present the close, minimize,
  and zoom title-bar controls and MUST be user-resizable.
- **window-title**: The window title MUST be the project's display name.
- **unified-toolbar**: The window MUST install a unified toolbar containing,
  in order, a flexible space, a search field, and a help button.
- **tab-group-creation**: Creating a project tab MUST create one member tab
  on every currently enabled edge, all sharing one title and one working
  directory, and MUST select the first member created.
- **group-close-scope**: Requesting to close any one member tab MUST remove
  every member of its group from every enabled edge.
- **last-group-guard**: The window MUST NOT close a tab group when it is the
  project's only remaining group.
- **last-edge-guard**: The window MUST NOT disable an edge when doing so
  would leave every edge disabled.
- **edge-top-up**: Enabling an edge MUST create one member tab per existing
  group on that edge if it does not already have one, using the active
  tab's current split arrangement (with fresh node ids) as the starting
  layout, or the project's layout blueprint if no tab exists yet.
- **title-tab-fallback**: A tab whose data source is absent, or whose data
  source declines to supply an item, MUST render as a plain title button
  showing the tab's stored title.
- **arrangement-mirroring**: Whenever the active tab's split tree changes
  shape or a divider moves, the window MUST apply the same shape and
  sizes — never the same node ids — to every other tab in the project.
- **structural-change-persistence**: A split, pane close, tab
  add/remove/reorder/select, or edge toggle MUST synchronously persist every
  tab's current layout tree, the active tab id, and the enabled-edge set to
  the project. A divider-thickness change is the one exception to that
  synchronous path: the tabbed content debounces it 300ms before the
  resulting layout change reaches this persist, and that pending write is
  flushed explicitly when the window closes (see **divider-flush-on-close**).
- **focused-leaf-debounce**: A change to which leaf pane is focused MUST be
  written to the project no sooner than 250ms after the change settles,
  rather than synchronously.
- **arrange-titlebar-button**: The window MUST show a trailing title-bar
  accessory button that toggles arrange mode for the window and is tinted
  with the resolved accent color while arrange mode is enabled.
- **settings-titlebar-button**: The window MUST show a trailing title-bar
  accessory button that presents project settings as a sheet on the window.
- **arrange-menu-state**: A menu item bound to the arrange-mode action MUST
  show a checked state whenever arrange mode is enabled for the window and
  unchecked otherwise.
- **search-target**: The pane the search field targets MUST be whichever
  pane the window last recomputed the field's enabled state and placeholder
  from. That recomputation happens whenever the active pane changes (tab
  activation, an active-pane notification, or the window being shown), so
  the target tracks the active pane at the moment of the last such
  refresh, not necessarily whichever pane is active at the instant of a
  keystroke.
- **search-routing**: Typing into the toolbar search field MUST forward the
  query, live, to the search target (see **search-target**).
- **search-availability**: The search field MUST be disabled whenever the
  search target does not support search, and its placeholder MUST read
  "Search" when the search target supplies none.
- **search-target-clearing**: When the search target changes, the field's
  text MUST be cleared.
- **status-footer-content**: The footer MUST show the project's display
  name, the active tab's title, the active pane's resolved title, and the
  active pane's selection description, omitting any that are empty, joined
  with the separator `" › "`.
- **help-drawer-toggle**: Invoking the help action MUST open the drawer if
  it is closed and close it if it is open.
- **help-visibility-persistence**: Whether the help drawer was left open
  MUST be remembered per project, not globally, and reapplied the next time
  that project's window is shown.
- **help-tab-width-persistence**: The drawer's selected tab and its dragged
  width MUST be remembered per project once help has been disclosed at
  least once in the window's lifetime, and MUST NOT be written before that
  first disclosure.
- **help-glyph-state**: The help button's icon MUST switch between an
  outlined and a filled question-mark glyph depending on whether the drawer
  is disclosed, and its tooltip MUST switch between "Show Help" and "Hide
  Help" to match, while its fixed accessibility name ("Help") MUST NOT
  change.
- **tab-activation-focus**: Activating a project tab MUST restore keyboard
  focus to that tab's last-focused leaf pane, deferred until after the
  tab's view hierarchy is mounted.
- **pane-teardown-on-close**: Closing the window MUST tear down every pane
  in every tab (releasing per-pane resources such as shells or file
  watchers) and MUST stop persisting the tab set from that point on.
- **divider-flush-on-close**: If the project already has stored tabs,
  closing the window MUST flush any pending divider-thickness persist
  before tearing the panes down.
- **reload-persist-suppression**: While a tab-reload operation's removal
  loop is running, the window MUST suppress the persist, focus-restore, and
  chrome-refresh side effects that an intermediate tab-selection change
  would otherwise trigger.
- **pane-enumeration-order**: Enumerating every pane in the window MUST
  order them by tab, then by edge in the fixed order top, right, bottom,
  left, then by each split's own leaf order.
- **scripting-tab-selection**: Setting the active tab by group id MUST
  select that group's member on the first enabled edge that has one, and
  MUST be ignored if the id names no group in this window.
- **redundant-tab-selection-guard**: Selecting a tab that is already active
  MUST NOT re-run tab-activation side effects (focus restore, persist,
  chrome refresh) a second time.
- **edge-set-assignment-order**: Assigning the enabled-edge set MUST enable
  every named edge before disabling any edge that is not named, so that
  reassigning the enabled-edge set never fails the last-enabled-edge
  refusal on an intermediate step.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

