
- **dims-content-with-scrim**: Component MUST paint its own layer's
  background as the theme's window-background role at 72% opacity.
- **paints-toolbar-surface**: The toolbar container MUST render with an 8pt
  corner radius, a 1pt border, a background color of the theme's
  elevated-surface role, and a border color of the theme's border role.
- **applies-theme-immediately-and-on-change**: Component MUST apply the
  active theme's colors to itself and the toolbar immediately when
  constructed, and MUST reapply them every time the active theme changes
  thereafter.
- **centers-toolbar-column**: Component MUST center a column holding the
  pane-name label above the toolbar, with 10pt spacing between them,
  horizontally and vertically within its own bounds.
- **caps-name-label-width**: The pane-name label's width MUST be constrained
  to at most the overlay's own width minus 16pt.
- **truncates-name-label-tail**: The pane-name label MUST truncate
  overflowing text at the tail and MUST be center-aligned.
- **toolbar-can-overhang-narrow-pane**: Component MUST NOT constrain the
  centered column's leading, trailing, top, or bottom edges to its own
  bounds, so a toolbar wider than a narrow pane is allowed to overhang the
  pane's edges rather than forcing the pane wider.
- **updates-pane-name-on-assignment**: Assigning a new value to `paneName`
  MUST update the pane-name label's displayed text synchronously.
- **exposes-add-button-as-anchor-view**: `addButtonView` MUST return the
  exact view instance of the Add button.
- **invokes-add-callback-on-tap**: Clicking or activating the Add button MUST
  invoke the `onAdd` callback when one is set, and MUST have no observable
  effect when it is unset.
- **invokes-remove-callback-on-tap**: Clicking or activating the Remove
  button MUST invoke the `onRemove` callback when one is set, and MUST have
  no observable effect when it is unset.
- **invokes-done-callback-on-tap**: Clicking or activating the Done button
  MUST invoke the `onDone` callback when one is set, and MUST have no
  observable effect when it is unset.
- **invokes-move-callback-on-selection**: Choosing a direction from the Move
  menu MUST invoke the `onMove` callback, when set, with that direction, and
  MUST have no observable effect when it is unset.
- **add-button-enablement-tracks-can-add**: Refreshing availability MUST set
  the Add button's enabled state to the current result of the `canAdd`
  callback.
- **remove-button-enablement-tracks-can-remove**: Refreshing availability
  MUST set the Remove button's enabled state to the current result of the
  `canRemove` callback.
- **move-menu-rebuilt-on-refresh**: Refreshing availability MUST discard and
  rebuild the Move menu's items on every call: it MUST keep the menu's own
  non-selectable title item first, then append exactly one item per
  direction (four fixed values — left, right, above, below — displayed
  respectively as Left, Right, Up, Down), in that fixed order (Left, Right,
  Up, Down).
- **move-item-enablement-tracks-available-directions**: Each rebuilt Move
  menu item's enabled state MUST equal whether the `availableDirections`
  callback's result contains that item's direction at the time of the
  rebuild.
- **move-button-enablement-tracks-items**: Component MUST enable the Move
  button if and only if at least one of its four rebuilt items is enabled.
- **move-items-icons-match-direction**: Each Move menu item MUST display an
  icon matching its direction (the `arrow.left`/`arrow.right`/`arrow.up`/
  `arrow.down` icons for Left, Right, Up, Down respectively), with an
  accessibility description equal to its title.
- **toolbar-buttons-show-icon-and-label**: The Add, Remove, and Done buttons
  MUST each display a leading icon (`plus`, `minus`, `checkmark`,
  respectively) alongside their text title, with an accessibility
  description equal to that title.
- **refresh-is-caller-driven**: Component MUST NOT observe or poll `canAdd`,
  `canRemove`, or `availableDirections` on its own; the Add, Remove, and
  Move controls MUST remain at whatever enabled state was last computed
  until availability is refreshed again.
- **computes-initial-availability-at-construction**: Component MUST refresh
  availability once during initialization.
- **root-and-controls-carry-accessibility-identifiers**: The root view and
  the Add, Remove, Move, and Done controls, and the pane-name label, each
  MUST carry a fixed accessibility identifier (`composable-tabs.arrange.scrim`,
  `.add`, `.remove`, `.move`, `.done`, and `.pane-name`, respectively).
- **move-items-carry-prefixed-identifiers**: Each Move menu item's
  accessibility identifier MUST be the fixed prefix
  `composable-tabs.arrange.move` followed by a period and that item's
  lowercased movement name (e.g. `composable-tabs.arrange.move.left`).
- **done-button-has-no-key-equivalent**: The Done button MUST NOT be
  assigned a key equivalent.
- **scrim-blocks-clicks-to-content**: Component MUST cover the pane's content
  so pointer clicks aimed at that content do not reach it while the overlay
  is present.
- **scrim-click-still-reaches-pane-selection**: An unhandled click on the
  scrim's own bounds (outside its buttons) MUST still be able to reach the
  pane's background view above it in the event-handling chain, so clicking a
  dimmed pane still selects it.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

