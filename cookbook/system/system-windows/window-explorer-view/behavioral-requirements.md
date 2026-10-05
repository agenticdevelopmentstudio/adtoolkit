
- **header-bar**: The view MUST show a header row containing, in
  order, a magnifying-glass icon, the label "Windows", a flexible spacer, and
  a refresh button.
- **refresh-button-loading-state**: The refresh button MUST be disabled
  whenever a window scan is in progress (`isLoading == true`).
- **initial-refresh**: The view MUST start a window scan the first time
  it appears.
- **activation-refresh-when-accessibility-missing**: The view MUST
  start a new window scan whenever the app becomes active again, but only
  if the most recent scan left `needsAccessibility == true`.
- **external-notification-refresh**: When constructed with a configured
  `refreshNotification` name, the view MUST start a window scan whenever a
  notification with that name is posted; when no name is configured,
  this path MUST have no effect.
- **accessibility-banner-visibility**: The view MUST
  display a banner reading "Accessibility permission needed for window
  titles." with an "Open Settings" action whenever the most recent scan
  found running windows but no process's Accessibility window-list
  query succeeded (`needsAccessibility == true`, set from `axSucceeded ==
  false`). This depends on Accessibility *query* success per process, not on
  whether any window's title was actually matched and replaced — a query can
  succeed for a process without any of its windows matching a system-reported
  window closely enough to replace its title.
- **accessibility-banner-action**: Activating the banner's
  "Open Settings" action MUST request Accessibility permission.
- **loading-state**: While a scan is in progress, the view MUST show an
  indeterminate progress indicator and the text "Scanning windows..." in
  place of the window list.
- **empty-state**: When a completed scan produces no application
  groups, the view MUST show a "No windows found" message together with the
  hint "Make sure Accessibility permission is granted."
- **app-grouping**: Once loaded, the view MUST present windows as
  one section per owning application, with sections ordered
  case-insensitively ascending by application name.
- **app-section-header**: Each application section header MUST show
  that application's running icon (or a fallback generic application icon
  when no running icon is found), the application name, and a count of its
  windows in that section.
- **section-select-all-toggle**: Each application section
  header MUST include a toggle that, when turned on, adds every selectable
  window in that section to `selectedWindowIDs`, and, when turned off,
  removes every selectable window in that section from `selectedWindowIDs`.
- **select-all-toggle-partial-selection-state**: A section's select-all toggle
  MUST show the unchecked state unless the section has at least one
  selectable window and every selectable window in it is currently selected.
- **select-all-toggle-availability**: A section's select-all
  toggle MUST be disabled when that section has no selectable windows.
- **window-row**: Each window row MUST show a toggle bound to that
  window's membership in `selectedWindowIDs`, the window's title (or
  "(untitled)" when the title is empty) limited to one line with middle
  truncation, and the window's dimensions formatted as
  `"<width>x<height>"` using integer point values.
- **window-context-badge**: A window row MUST show a badge
  naming its owning context, colored from that context's stored color,
  whenever the window already belongs to a context and either no
  `activeGroupID` is set or that context differs from `activeGroupID`.
- **window-row-selectability-state**: A window row's toggle MUST be
  disabled, and its title MUST be drawn in the secondary text color instead
  of the primary text color, whenever the window is not selectable.
- **window-selectability**: A window MUST be selectable
  when it belongs to no context, or when it belongs to the context
  identified by `activeGroupID`; it MUST NOT be selectable when it belongs
  to any other context.
- **scan-window-filter**: A window scan MUST include only windows that
  belong to a regular, user-visible running application, are wider than 50
  points, are taller than 50 points, are currently on-screen, whose owning
  application name is not in `appState.settings.hiddenApps`, and whose id is
  not in the view's `excludeWindowIDs`.
- **per-process-accessibility-query**: A window scan MUST query the
  Accessibility window list of every distinct process id among the
  filtered windows, skipping any process for which that query does not
  succeed.
- **accessibility-title-match**: A window scan MUST
  replace a window's title with an Accessibility window's title when that
  Accessibility window belongs to the same process and its position and size
  each differ from the system-reported window's frame by less than 3 points
  on x, y, width, and height, and that Accessibility title is non-empty;
  otherwise the window's original title MUST be kept unchanged.
- **discovery-mode-stale-selection-pruning**: When `activeGroupID` is nil,
  completing a scan MUST remove from `selectedWindowIDs` any id that is not
  present among the windows the scan produced.
- **assignment-mode-selection-preservation**: When `activeGroupID` is
  non-nil, completing a scan MUST NOT remove any id from
  `selectedWindowIDs`, even if the window it identifies is not present among
  the windows the scan produced.

