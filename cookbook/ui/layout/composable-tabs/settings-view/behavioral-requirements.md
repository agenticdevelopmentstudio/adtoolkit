
- **constructs-topic-list-from-closures**: Component MUST construct its
  topic list during its own initialization, passing through the
  `isEdgeEnabled` and `setEdgeEnabled` closures it was given.
- **tags-window-background-role**: Component MUST set its root view's
  background to the `.windowBackground` theme role.
- **identifies-sheet-root**: Component MUST set the root view's accessibility
  identifier to `project-window.project-settings`.
- **embeds-topic-list-as-child**: Component MUST add the topic list as a
  child element of the root view and MUST make its view a subview of the
  root view.
- **pins-panel-to-top-leading-trailing**: Component MUST pin the topic list's
  view to the root view's top, leading, and trailing edges, and MUST NOT pin
  it to the root view's bottom edge (the Done button occupies the remaining
  space below it).
- **renders-done-button**: Component MUST render a rounded-style button
  titled "Done" below the topic list.
- **binds-return-key-to-done**: Component MUST bind the Done button's
  activation shortcut to the Return key.
- **identifies-done-button**: Component MUST set the Done button's
  accessibility identifier to `project-window.project-settings.done`.
- **lays-out-done-button-offsets**: Component MUST position the Done button
  12pt below the topic list's bottom edge, 20pt inside the root view's
  trailing edge, and 16pt above the root view's bottom edge.
- **dismisses-on-done**: Component MUST dismiss the sheet when the Done
  button's action fires.
- **applies-changes-live**: Component MUST apply every setting change
  immediately as the user makes it, with no separate commit or cancel
  action anywhere in the component — every mutation (`setEdgeEnabled`, the
  bound spacing-control writes) takes effect on the underlying state the
  moment it happens.
- **sizes-preferred-content**: Component MUST size its preferred content area
  to 760×520 points.
- **titles-sidebar-project**: The topic list MUST title its sidebar
  "Project".
- **widens-detail-pane**: The topic list MUST enforce a minimum detail-pane
  width of 420pt.
- **fixes-sidebar-width**: The topic list MUST size its sidebar to its
  content rather than a user-draggable width.
- **presents-help-as-popover**: The topic list MUST present its help content
  in a popover rather than a drawer-style presentation.
- **registers-two-panels-in-order**: The topic list MUST register the Tabs
  panel before the Spacing panel and MUST select the Tabs panel once both
  are registered.
- **lists-edges-in-reading-order**: The Tabs panel MUST present the window's
  four edges in the fixed order Top, Right, Bottom, Left.
- **labels-tabs-descriptor**: The Tabs panel MUST label itself with the
  title "Tabs" and an icon representing a grid of tab bars.
- **groups-edge-checkboxes**: The Tabs panel MUST place all four edge
  toggles inside a single group titled "Tab Bars".
- **reflects-initial-edge-state**: The Tabs panel MUST initialize each
  toggle's state from `isEdgeEnabled(edge)`, setting it on when it returns
  `true` and off when it returns `false`.
- **identifies-edge-checkboxes**: The Tabs panel MUST set each toggle's
  accessibility identifier to `project-settings.tabs.` followed by the
  edge's raw value (`top`, `right`, `bottom`, or `left`).
- **themes-checkbox-title-color**: The Tabs panel MUST repaint each toggle's
  title using the active theme's primary-text color and body text style
  whenever the theme changes.
- **commits-edge-toggle**: The Tabs panel MUST call
  `setEdgeEnabled(edge, isOn)` whenever a toggle's action fires with a
  value mapping to a valid edge.
- **reverts-checkbox-to-authoritative-state**: The Tabs panel MUST, in the
  same action handler and immediately after calling `setEdgeEnabled`,
  re-read the toggled control's displayed state from `isEdgeEnabled(edge)`
  and set the control's state from that read — not from the click that
  triggered the handler. This is how a refused attempt to disable the
  window's last enabled edge becomes visible on screen: the window's own
  refusal (reported back through `isEdgeEnabled`) overrides the toggle's
  own state.
- **guards-invalid-checkbox-tag**: The Tabs panel MUST NOT act on a toggle
  action whose index does not map to one of the four edges; the handler
  MUST return without calling `setEdgeEnabled` in that case.
- **labels-spacing-descriptor**: The Spacing panel MUST label itself with
  the title "Spacing" and an icon representing a 2×2 grid of panes.
- **groups-frame-and-divider-controls**: The Spacing panel MUST place the
  frame-spacing control inside a group titled "Frame Spacing" and the
  divider-spacing control inside a separate group titled "Pane Divider
  Spacing".
- **binds-frame-spacing-to-settings**: The Spacing panel MUST construct its
  frame-spacing control bound live to the app-wide frame-spacing settings
  for every edge.
- **binds-divider-spacing-to-settings**: The Spacing panel MUST construct
  its divider-spacing control bound live to the app-wide pane-divider
  gutter settings.
- **closes-tab-loop-between-spacing-controls**: The Spacing panel MUST link
  keyboard focus so tabbing forward from the frame-spacing control's last
  field moves to the divider-spacing control's first field, and tabbing
  forward from the divider-spacing control's last field returns to the
  frame-spacing control's first field, so Tab cycles between the two
  controls without leaving the panel.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

