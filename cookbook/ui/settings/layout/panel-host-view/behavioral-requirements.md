
- **replaces-content-on-set**: The component's set-content operation,
  called with a present view, MUST remove every existing child of the
  content container before installing the given view.
- **clears-content-on-nil**: The set-content operation, called with no
  view, MUST remove every existing child of the content container and
  MUST NOT install a replacement, leaving the content area empty.
- **content-pinned-to-container-edges**: An installed content view MUST be
  pinned to its content container's top, leading, trailing, and bottom
  edges with zero inset.
- **content-container-pinned-to-view-edges**: The content container itself
  MUST be pinned to the component's own top, leading, trailing, and bottom
  edges with zero inset.
- **help-button-inset-from-content-container**: The help button's top edge
  MUST sit 12pt below the content container's top edge, and its trailing
  edge MUST sit 12pt inside the content container's trailing edge.
- **help-button-above-content**: The help button MUST be added as a
  child of the component itself, after the content container, so
  swapping the hosted content never removes, reorders, or redraws the
  button.
- **help-button-visibility**: The help button MUST be hidden whenever the
  show-help-button setting is off, or whenever no help presenter is
  assigned, or both, and MUST be visible whenever the show-help-button
  setting is on and a help presenter is assigned.
- **help-button-icon-reflects-visibility**: The help button MUST display a
  filled question-mark icon while the assigned help presenter reports help
  as visible, and an outlined question-mark icon otherwise (including when
  no presenter is assigned).
- **help-button-symbol-configuration**: The help button's icon MUST be
  rendered at 15pt point size with regular weight.
- **help-button-tint-reflects-visibility**: The help button's tint color
  MUST be the active theme palette's accent-color role while help is
  visible, and the palette's secondary-text-color role while help is not
  visible.
- **help-button-tooltip-reflects-visibility**: The help button's tooltip
  MUST read "Hide Help" while help is visible, and "Show Help" while it is
  not.
- **help-button-accessibility-label-fixed**: The help button's
  accessibility label MUST be the literal string "Help", set once at
  construction, regardless of visibility state.
- **help-button-keyboard-focusable**: The component MUST NOT remove the
  help button from the keyboard/assistive-technology focus order, and MUST
  NOT override its default activation behavior, while the button is
  visible (see Platform Notes for the source's exact mechanism).
- **help-button-borderless-image-only**: The help button MUST render with
  no border and MUST show only its icon, with no accompanying text label.
- **help-button-momentary-type**: The help button MUST behave as a
  momentary push control — firing its action once per click and holding
  no on/off state of its own — rather than as a persistent toggle.
- **toggle-help-delegates-to-presenter**: The component's toggle-help
  operation MUST forward to the assigned help presenter's own toggle-help
  operation, and MUST have no effect when no presenter is assigned.
- **help-anchor-claimed-when-button-shown**: Whenever the show-help-button
  setting is on, the component MUST set the assigned help presenter's
  anchor view to its own help button, both when a presenter is assigned
  and when the show-help-button setting changes.
- **help-anchor-untouched-when-button-hidden**: Whenever the show-help-button
  setting is off, the component MUST NOT modify the assigned help
  presenter's anchor view.
- **help-visibility-change-refreshes-button**: Whenever the current
  presenter invokes its own visibility-change notification, the component
  MUST re-evaluate and reapply the help button's icon, tint, and tooltip.
- **help-visibility-change-notifies-external-observer**: Whenever the
  current presenter invokes its own visibility-change notification, the
  component MUST, after refreshing its own button, invoke its own external
  visibility-change notification if one is set.
- **presenter-reassignment**: Assigning a new help presenter MUST install
  this component's own callback as that new presenter's visibility-change
  notification, MUST re-run the help-anchor claim, MUST hand the new
  presenter the component's currently stored help content via its
  set-help operation, and MUST refresh the help button.
- **set-help-forwards-to-presenter**: The component's set-help operation
  MUST store the given help content (including no content), MUST forward
  that same value to the assigned help presenter's own set-help operation,
  and MUST refresh the help button afterward.
- **is-help-visible-reflects-presenter-or-false**: The component's
  help-visible query MUST report the assigned help presenter's own
  help-visible value when a presenter is assigned, and MUST report false
  when no presenter is assigned.
- **shows-help-button-toggle**: Changing the show-help-button setting MUST
  re-run the help-anchor claim and MUST refresh the help button.
- **theme-change-refreshes-button-tint**: The component MUST re-run the
  help button refresh (icon, tint, tooltip) immediately whenever the
  active theme palette changes.
- **rejects-deserializing-construction**: The component MUST NOT support
  construction via a deserializing/decoding-based construction path; that
  path MUST trigger a failure rather than produce a usable instance (see
  Platform Notes for the source's exact mechanism).
- **constraint-based-layout-only**: The component MUST position itself,
  its content container, and its help button entirely through the
  platform's layout-constraint system, never by assigning frames manually
  (see Platform Notes for the source's exact mechanism).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

