
- **identifies-window-as-settings**: The window MUST be registered under the
  fixed window id `"settings"`, so the app tracks one Settings window rather
  than one per instance.
- **titles-window-settings**: The window's title text MUST be `"Settings"`.
- **hides-window-title-visibility**: The window MUST hide its title text from
  the title bar, deferring to the header bar's panel-title item to show what
  is on screen.
- **extends-content-under-title-bar**: The window MUST remain titled,
  closable, miniaturizable, and resizable, and MUST extend its content area
  under the title bar so the sidebar can run the full height of the window
  (see Platform Notes for the exact style mask).
- **suppresses-sidebar-title**: The hosted split view MUST show no sidebar
  title.
- **shows-sidebar-search**: The hosted split view MUST show a search field in
  the sidebar.
- **sorts-panels-alphabetically**: The hosted split view MUST sort its panels
  alphabetically by title, so panels always list in alphabetical order
  regardless of registration order.
- **exposes-setting-panels**: Setting the panel list MUST replace the hosted
  split view's full panel set; reading it before the split view has loaded
  MUST return an empty list.
- **activates-app-on-show-by-default**: The window's activate-on-show
  behavior MUST default to enabled.
- **allows-subclass-to-disable-activation**: A host MAY disable activate-on-
  show so that showing the window does not activate the app.
- **skips-activation-when-disabled**: When activate-on-show is disabled,
  showing the window MUST perform only the base show behavior — it MUST NOT
  activate the app or make the window key on top of that.
- **shows-quietly-under-quiet-presentation**: When activate-on-show is
  enabled and quiet presentation is enabled, showing the window MUST make the
  window key without activating the app or ordering it above other
  applications' windows.
- **activates-and-keys-window-normally**: When activate-on-show is enabled
  and quiet presentation is not enabled, showing the window MUST activate the
  app and then make the window key and frontmost.
- **attaches-help-drawer-presenter**: Configuring the window MUST construct a
  help panel presenter for that window and assign it as the hosted split
  view's help presenter.
- **installs-unified-toolbar-chrome**: Configuring the window MUST install a
  unified, icon-only header bar that the user cannot customize, with a
  transparent title bar and no separator line between the title bar and the
  content below it.
- **fixes-toolbar-item-order**: The header bar's item order MUST be fixed,
  for both the default set and the allowed set, in this order: the sidebar
  tracking separator, the back/forward navigation control, the panel-title
  item, a flexible space, and the help control.
- **hides-inline-help-button**: Configuring the window MUST hide the hosted
  split view's own inline help control, since the header bar supplies the
  window's one help control.
- **builds-back-forward-as-one-control**: The back/forward control MUST be a
  single control with two segments — a back-facing chevron labeled "Back"
  and a forward-facing chevron labeled "Forward" — carrying one combined
  accessibility label, "Back and forward", rather than two independent
  buttons.
- **routes-segment-selection-to-navigation**: Choosing the back segment MUST
  navigate back; choosing the forward segment MUST navigate forward; no
  selection MUST trigger neither.
- **syncs-navigation-control-enablement**: Whenever the navigation state
  changes, the back segment MUST be enabled only when moving back is
  possible and the forward segment enabled only when moving forward is
  possible, each set independently, because a custom-view header-bar item
  receives no automatic validation pass.
- **shows-current-panel-title**: Whenever the navigation state changes, the
  panel-title item's text MUST be set to the current panel's title, or the
  empty string when there is none.
- **renders-panel-title-as-single-line-heading**: The panel-title item MUST
  show its text as a non-editable, single-line heading using the heading
  text role and the primary-text color role, truncating overflow at the end,
  and MUST hug its content horizontally rather than stretching.
- **shows-outline-glyph-when-drawer-closed**: While the help panel is closed,
  the help control's icon MUST be an outline question-mark icon.
- **shows-filled-glyph-when-drawer-open**: While the help panel is open, the
  help control's icon MUST be a filled question-mark icon.
- **tints-help-button-by-drawer-state**: The help control's tint MUST be the
  resolved theme palette's secondary-text color role while the panel is
  closed and its accent color role while the panel is open.
- **swaps-help-tooltip-by-drawer-state**: The help control's tooltip MUST
  read "Show Help" while the panel is closed and "Hide Help" while the panel
  is open.
- **keeps-help-accessibility-name-stable**: The help control's accessibility
  description MUST remain "Help" across every icon swap; it MUST NOT change
  to match the tooltip text.
- **updates-help-glyph-on-visibility-change**: Whenever the help panel's
  visibility changes, the help control's icon, tint, and tooltip MUST be
  refreshed to match the panel's current visibility.
- **updates-help-glyph-on-navigation-change**: Whenever the navigation state
  changes, the help control's icon, tint, and tooltip MAY also be refreshed,
  since one implementation may share a single refresh path across
  navigation and help state; an implementer is not required to refresh the
  help control on navigation alone (see Platform Notes for
  the shared private method this rides on).
- **wires-help-only-for-inserted-item**: The help control's live reference,
  its live theme tracking, and its help-anchor assignment MUST be attached
  only when the control being built is actually the one being inserted into
  the header bar — never for a customization-palette sample or a rebuild
  pass — so a discarded copy cannot leave the tracked help control pointing
  at a view that is off screen.
- **anchors-help-presenter-to-button**: When the help control is actually
  inserted, it MUST be assigned as the help presenter's help-anchor view.
- **tracks-theme-live-on-help-button**: The inserted help control MUST
  re-apply its icon/tint/tooltip whenever the resolved theme palette
  changes, tracked live, not only once at construction.
- **toggles-help-on-click**: Activating the help control MUST toggle the
  help panel's visibility.
- **builds-tracking-separator-from-splitview**: The sidebar tracking
  separator item MUST be bound to the hosted split view's divider nearest
  the sidebar, and MUST be absent if the split view does not currently
  exist.
- **assigns-high-visibility-to-primary-items**: The navigation control, the
  panel-title item, and the help control MUST each be given high visibility
  priority.
- **returns-nil-for-unknown-toolbar-identifier**: Requesting an item for any
  identifier outside the fixed list in **fixes-toolbar-item-order** MUST
  return nothing.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

