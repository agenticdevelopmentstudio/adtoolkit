
- **Role/trait**: Not explicitly set anywhere in source; the two choice
  lists and two buttons use the platform's default pop-up/button roles, and
  the two row captions use the default static-text role.
- **Label requirements**: A test-automation identifier is set on the
  container ("composable-tabs.add-pane"), both choice lists
  ("composable-tabs.add-pane.view", "composable-tabs.add-pane.where"), and
  both buttons ("composable-tabs.add-pane.cancel",
  "composable-tabs.add-pane.ok") — these back UI-test lookup, not a screen
  reader's spoken label. Cancel and OK derive their spoken label from their
  own visible titles ("Cancel", "OK"). Each offered entry with an icon gets
  an explicit accessibility description (the entry's display name) on its
  item's image. Per **associates-popup-with-row-caption**, neither choice
  list is associated with its row caption ("Add:" / "Where:") anywhere in
  source, so a screen reader announces only the choice's current value
  (e.g. "Right") without the "Where" context a sighted user gets from the
  adjacent label.
- **Announce state changes**: Not applicable — the sheet has no dynamic
  reload or asynchronous state; the only state changes are direct results
  of the user's own selections and button activations, which the platform
  announces on its own via the controls' native accessibility behavior.
- **Minimum tap target**: Not applicable in the touch sense — this is a
  pointer/keyboard-driven sheet; both choice lists and buttons use the
  platform's default control metrics, with no custom frame or height
  override in source. Touch tap-target minimum guidance does not apply here,
  since this is not a touch-driven control.

