
- **populates-view-popup-from-choices**: The "Add" choice list MUST contain
  exactly one item per offerable entry, in the order given, titled with that
  entry's display name.
- **sets-choice-icon-when-symbol-present**: When an offerable entry's icon is
  set, the "Add" choice list MUST set that item's image to the named icon,
  with an accessibility description equal to the entry's display name.
- **omits-choice-icon-when-symbol-absent**: When an offerable entry's icon is
  unset, the "Add" choice list MUST leave that item without an image.
- **populates-where-popup-in-fixed-order**: The "Where" choice list MUST
  contain exactly four items, titled "Left", "Right", "Above", "Below" in
  that fixed order, regardless of the offered entries.
- **defaults-where-selection-to-right**: The "Where" choice list's initial
  selection MUST be "Right".
- **arranges-add-and-where-as-two-row-grid**: The "Add" and "Where"
  label/choice pairs MUST be laid out as a two-row, two-column grid, not a
  form list or stack.
- **add-row-precedes-where-row**: The "Add" row MUST appear above the "Where"
  row in the grid.
- **ok-button-disabled-when-choices-empty**: The OK button MUST be disabled
  at load time when no entries are offered.
- **ok-button-enabled-when-choices-present**: The OK button MUST be enabled
  at load time when at least one entry is offered.
- **ok-button-enabled-state-fixed-at-load**: The OK button's enabled state
  MUST be computed once, from the offered entries, at load time; enablement
  depends only on whether entries were offered, not on either choice's
  selection.
- **cancel-precedes-ok-in-button-order**: The Cancel button MUST be
  positioned before the OK button, left to right.
- **cancel-bound-to-escape-key**: The Cancel button's key equivalent MUST be
  the Escape key.
- **ok-bound-to-return-key**: The OK button's key equivalent MUST be the
  Return key.
- **cancel-dismisses-without-invoking-onadd**: Activating Cancel MUST
  dismiss the sheet and MUST NOT report a selection.
- **confirm-dismisses-before-invoking-onadd**: Activating OK with a valid
  selection MUST dismiss the sheet before reporting the selection to the
  caller.
- **confirm-invokes-onadd-with-selection**: Activating OK MUST, when both
  choices have a valid selected index, report to the caller the view
  identifier of the selected entry and the direction at the selected "Where"
  index.
- **confirm-dismisses-without-onadd-on-invalid-selection**: Activating OK
  MUST dismiss the sheet without reporting a selection when the "Add"
  choice's selected index is not a valid index into the offered entries, or
  the "Where" choice's selected index is not a valid index into the four
  fixed directions.
- **enforces-minimum-container-width**: The container view's width MUST be
  constrained to at least 320 points.
- **root-view-accessibility-identifier**: The root container view MUST
  carry the accessibility identifier "composable-tabs.add-pane".
- **view-popup-accessibility-identifier**: The "Add" choice list MUST carry
  the accessibility identifier "composable-tabs.add-pane.view".
- **where-popup-accessibility-identifier**: The "Where" choice list MUST
  carry the accessibility identifier "composable-tabs.add-pane.where".
- **cancel-button-accessibility-identifier**: The Cancel button MUST carry
  the accessibility identifier "composable-tabs.add-pane.cancel".
- **ok-button-accessibility-identifier**: The OK button MUST carry the
  accessibility identifier "composable-tabs.add-pane.ok".
- **add-row-label-text**: The "Add" row's label MUST display the
  right-aligned text "Add:".
- **where-row-label-text**: The "Where" row's label MUST display the
  right-aligned text "Where:".
- **associates-popup-with-row-caption**: Each choice list SHOULD be
  associated with its row's caption ("Add:" / "Where:") so a screen reader
  announces the caption together with the choice's current value.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

