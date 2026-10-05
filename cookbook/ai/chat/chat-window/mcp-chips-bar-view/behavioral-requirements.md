
- **applies-theme-consistently**: The bar's content and the popover's content MUST both receive the app's active theme values (see Platform Notes for the mechanism).
- **fills-parent-bounds**: The bar MUST stretch to exactly fill the bounds of its containing element on every edge.
- **shares-one-view-model-between-bar-and-picker**: The bar's toggle button
  and the popover's server rows MUST reflect the same active-server state,
  backed by a single view model constructed at initialization from the given
  `registry` and `activeServerIds` binding — so toggling a row in the popover
  is immediately reflected in the bar's button label.
- **snapshots-active-ids-at-init**: The view model's `activeServerIds` MUST
  be set to the current value of the caller's `activeServerIds` binding at
  construction time, read exactly once.
- **subscribes-to-registry-clients**: The view model MUST subscribe to the
  registry's `clients` updates for its lifetime, so every update to
  `clients` is picked up without the caller re-observing manually (see
  Platform Notes for how the subscription is retained).
- **sorts-available-servers-by-name**: On every `clients` update,
  `availableServerIds` MUST be set to the clients' keys sorted by each
  client's `name`, ascending, using a locale-aware, case-insensitive
  comparison.
- **defaults-missing-name-to-empty-string-for-sort**: When comparing two ids
  for the sort in `sorts-available-servers-by-name`, a missing name lookup
  (`clients[id]?.name`) MUST be treated as `""`.
- **rebuilds-server-names-on-update**: On every `clients` update,
  `serverNames` MUST be replaced with a fresh mapping from each client id to
  that client's current `name`.
- **reports-active-membership**: `isActive(_:)` MUST return whether the
  given id is a member of `activeServerIds`.
- **toggles-membership-on-call**: `toggle(_:)` MUST remove the given id from
  `activeServerIds` if present, and MUST insert it if absent.
- **propagates-toggle-to-binding**: `toggle(_:)` MUST write the resulting
  `activeServerIds` set to the caller-supplied binding's value after every
  call.
- **renders-server-rack-icon**: The bar MUST display a server-rack icon,
  tinted with `theme.secondaryText`.
- **renders-toggle-button**: The bar MUST display one button whose label
  contains the computed button text followed by a chevron-down disclosure
  icon, both tinted with `theme.accent` and set in `theme.font(.caption)`.
- **computes-no-servers-label**: The button's text MUST read
  `"No MCP servers"` when `availableServerIds` is empty.
- **computes-none-active-label**: When `availableServerIds` is non-empty and
  the intersection of `activeServerIds` with `Set(availableServerIds)` is
  empty, the button's text MUST read `"MCP: none"`.
- **computes-count-active-label**: When that intersection is non-empty, the
  button's text MUST read `"MCP: {active} of {total}"`, where `active` is
  the intersection's count and `total` is `availableServerIds.count`.
- **uses-borderless-button-style**: The toggle button MUST use a borderless
  button style (see Platform Notes for the exact style name).
- **toggles-picker-on-tap**: Tapping the button MUST toggle the
  `showingPicker` state.
- **presents-popover-below-button**: The bar MUST present a popover, bound
  to `showingPicker`, anchored below the button (see Platform Notes for the
  exact anchoring mechanism).
- **reapplies-theme-inside-popover**: The popover's content MUST re-apply
  the app's active theme to the server picker's content, independently of
  the bar's own application (see Platform Notes for the mechanism and why a
  second application is needed).
- **applies-bar-padding**: The bar's root layout container MUST use 8pt
  inter-item spacing and MUST be padded 12pt horizontally and 6pt
  vertically.
- **trails-with-spacer**: The bar's root layout container MUST end with a
  flexible spacer after the toggle button.
- **shows-picker-heading**: The popover MUST display the text
  `"Active MCP Servers"` in `theme.font(.heading)`.
- **shows-empty-state-message**: When `availableServerIds` is empty, the
  popover MUST display the text `"No connected servers.\nAdd one in
  Settings → MCP Servers."`, tinted with `theme.secondaryText` and set in
  `theme.font(.caption)`, in place of any server row.
- **lists-one-toggle-row-per-server**: When `availableServerIds` is
  non-empty, the popover MUST render exactly one toggle row per id, in
  `availableServerIds`'s order, and MUST NOT render the empty-state message.
- **row-label-falls-back-to-unknown**: Each row's label MUST read
  `serverNames[id]` when present, and `"Unknown"` otherwise.
- **row-toggle-reflects-active-state**: Each row's toggle MUST be bound so
  reading it returns `viewModel.isActive(id)`.
- **row-toggle-calls-view-model-toggle**: Setting a row's toggle (to
  either value) MUST call `viewModel.toggle(id)`.
- **uses-checkbox-toggle-style**: Every row toggle MUST use a checkbox
  toggle style (see Platform Notes for the exact style name).
- **applies-picker-padding-and-min-width**: The popover's root layout
  container MUST use 8pt spacing, MUST be padded 14pt on all sides, and MUST
  have a minimum width of 220pt.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

