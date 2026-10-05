
### Identity & construction

- **nodeid-identity**: The pane MUST expose `nodeID`, a UUID given at
  construction, unchanged for the pane's lifetime.
- **pane-number-identity**: The pane MUST expose `paneNumber`, an integer
  given at construction, unchanged for the pane's lifetime.
- **view-id-identity**: The pane MUST expose `viewID`, the view identifier
  given at construction, unchanged for the pane's lifetime.
- **working-directory-identity**: The pane MUST expose `workingDirectory`,
  the file-system location given at construction, unchanged for the pane's
  lifetime, shared by every pane in the same split tree.

### Content hosting

- **content-from-registry**: The pane MUST build its content by asking the
  resolved layout's registry for content keyed by `viewID`, passing
  `nodeID`, the project, `workingDirectory`, `paneNumber`,
  `stateOwnerNodeID`, and the enclosing tab's root split node id.
- **content-nil-without-project**: The pane MUST return no content, without
  consulting any registry, when the project it depends on is no longer
  available.
- **content-layout-override-precedence**: The pane MUST resolve content
  against `layoutOverride`'s registry when `layoutOverride` is set, and
  against the project's own layout registry otherwise.
- **container-draws-active-outline**: The pane MUST use a container view
  keyed by `nodeID` that draws the active-pane outline described below.
- **content-inset-matches-border**: The pane MUST hold its title bar and
  content off the container's edges by the border inset (2pt), so the
  chrome never overlaps the active-pane border. This is the one place this
  inset is defined as a literal; every other requirement and the Appearance
  section below refer to it by name rather than repeating the number.

### Naming & identity strings

- **fallback-title-from-registry**: `fallbackTitle` MUST return the display
  name the resolved layout's registry has registered for `viewID`.
- **fallback-title-placeholder-layout**: When `layoutOverride` is unset and
  the project has already released, `fallbackTitle` MUST resolve the
  display name against a placeholder-only layout rather than crashing or
  returning an empty string.
- **accessibility-id-from-view-id**: `paneAccessibilityIdentifier` MUST be
  `"pane."` followed by the kebab-case slug of the last dot-separated
  component of `viewID`'s raw value.
- **accessibility-id-includes-pane-index**: When a pane index has been
  assigned, `paneAccessibilityIdentifier` MUST append `".<index>"` to the
  type identifier.
- **pane-index-update-is-idempotent**: Assigning a pane index MUST leave
  the container view's accessibility identifier untouched when the new
  index equals the index already assigned.
- **pane-index-update-refreshes-identifier**: Assigning a pane index MUST
  update the container view's accessibility identifier immediately when the
  index changes and the view is already loaded, and MUST NOT force the view
  to load when it is not.

### Lifecycle notifications

- **arrange-mode-change-scoped-to-own-window**: The pane MUST show or hide
  its arrange overlay in response to arrange mode's change notification
  only when that notification's window is this pane's own window.
- **layout-change-refreshes-overlay-globally**: The pane MUST refresh its
  installed arrange overlay's availability whenever any tab's layout
  changes, regardless of which window that change occurred in.
- **window-close-removes-overlay**: The pane MUST remove its arrange
  overlay when its own window closes.
- **pane-appearance-reevaluates-overlay**: The pane MUST re-evaluate
  whether the arrange overlay should be installed each time its view
  appears.

### Arrange overlay

- **overlay-tracks-arrange-mode**: The pane MUST install the arrange
  overlay when arrange mode is enabled for its window, and MUST remove it
  when arrange mode is disabled.
- **overlay-install-idempotent**: Installing the overlay when one already
  exists MUST NOT create a second overlay; it MUST instead refresh the
  existing overlay's availability.
- **overlay-inset-from-border**: The overlay MUST be inset from every edge
  of the pane by the border inset (see **content-inset-matches-border**),
  so it sits above content but inside the border.
- **overlay-shows-pane-name**: The overlay MUST display the pane's resolved
  title.
- **overlay-add-availability**: The overlay's Add control MUST report
  available exactly when at least one distinct, non-placeholder view id can
  legally be inserted beside this pane.
- **overlay-remove-availability**: The overlay's Remove control MUST report
  available exactly when the enclosing split reports this pane may be
  removed as a leaf.
- **overlay-move-availability**: The overlay's Move control MUST offer
  exactly the set of directions the enclosing split reports as legal for
  this pane.
- **overlay-done-disables-arrange-mode**: Activating the overlay's Done
  control MUST disable arrange mode for the pane's window.
- **overlay-installs-key-monitor**: Installing the overlay MUST install a
  mechanism that intercepts key-down events before the pane's content sees
  them; removing the overlay MUST remove that mechanism.

### Keyboard handling

- **exit-keys-disable-arrange-mode**: The pane MUST disable arrange mode
  for its window and consume the key event when Return, Enter, or Escape
  is pressed while arrange mode is enabled in the pane's own window.
- **arrow-key-moves-active-pane-only**: While arrange mode is enabled in
  the pane's own window, an arrow key matching one of the four move
  directions (Left, Right, Up, Down) MUST move this pane and consume the
  event only when this pane is that window's active pane (per the
  active-pane tracker); it MUST NOT act, and MUST NOT consume the event,
  otherwise.
- **key-monitor-ignores-other-windows**: The pane's key-event interception
  MUST take no action and MUST leave the event unconsumed when the event's
  window is not the pane's own window, or arrange mode is not enabled in
  that window.

### Move / gear menu

- **move-delegates-to-split**: Requesting a move MUST ask the enclosing
  split to move this pane in the given direction.
- **move-refusal-announced**: The pane MUST announce a refusal and take no
  other action when there is no enclosing split, or the enclosing split
  refuses the move.
- **gear-menu-move-submenu**: The gear menu MUST include exactly one "Move"
  item carrying the four move directions as its submenu, built from the
  same move-menu items the arrange overlay uses.
- **gear-menu-move-enablement**: The "Move" item MUST be enabled exactly
  when at least one of its four submenu items is enabled.

### Add

- **add-choices-exclude-placeholder**: The computed set of addable choices
  MUST exclude the placeholder view id.
- **add-choices-deduplicated**: The computed set of addable choices MUST
  contain at most one entry per distinct view id, even when the enclosing
  split reports that id insertable in more than one direction.
- **add-refused-when-empty**: Requesting Add MUST announce a refusal and
  MUST NOT present a picker when there are no addable choices.
- **add-picker-presentation**: The pane MUST present the add picker as a
  popover anchored to the overlay's Add button when the overlay is
  installed, and as a sheet when it is not.
- **add-selection-splits-pane**: Choosing a view id and direction from the
  add picker MUST ask the enclosing split to split this pane, inserting the
  chosen view id in the chosen direction.

### Remove

- **remove-refused-when-not-removable**: Requesting Remove MUST announce a
  refusal and MUST NOT remove the pane when the enclosing split reports
  this pane cannot be removed as a leaf.
- **remove-skips-confirmation-when-silent**: The pane MUST remove itself
  immediately, without a confirmation dialog, when its content supplies no
  removal-confirmation message.
- **remove-confirms-when-content-warns**: The pane MUST present a warning
  alert, titled "Remove this pane?" with the content's message and
  Remove/Cancel buttons, before removing, when its content supplies a
  removal-confirmation message.
- **remove-confirmation-modal-without-window**: The pane MUST run the
  confirmation alert as a blocking modal, and remove itself only if Remove
  is chosen, when it has no window.
- **remove-confirmation-sheet-reresolves-split**: The pane MUST present the
  confirmation alert as a window-attached sheet when it has a window, and
  MUST re-resolve the enclosing split at the sheet's completion — rather
  than reusing the split resolved before the sheet opened — before
  removing.

### Teardown & state

- **removal-notifies-content-teardown**: When the pane is about to be
  removed, it MUST remove the arrange overlay and MUST notify content
  implementing the teardown capability that its content will be discarded.
- **state-owner-retargets-store**: Setting `stateOwnerNodeID` MUST retarget
  the pane's persisted-state store to attribute state to the new value.
- **focus-check-skips-unloaded-view**: Checking whether this pane contains
  the input focus MUST report false without loading the pane's view when
  the view has not yet been loaded.
- **focus-check-walks-hierarchy**: When the view is loaded, checking
  whether this pane contains the input focus MUST report true exactly when
  the window's focused element is the pane's view or a descendant of it.
- **title-bar-bottom-constant**: `titleBarBottom` MUST equal the border
  inset (see **content-inset-matches-border**) plus the title bar's fixed
  26pt height (28pt total).

### Appearance fact

- **active-pane-cue-is-color-only**: As built, the pane's backdrop
  distinguishes the active pane from an inactive one by border color alone
  (`projectActivePaneOutline` vs. `projectPaneOutline`), with a constant
  2pt border width in both states. This describes the current
  implementation; it is not a constraint against adding a secondary cue —
  see Differentiate Without Color in Accessibility Options, which records
  that no such cue is implemented.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

