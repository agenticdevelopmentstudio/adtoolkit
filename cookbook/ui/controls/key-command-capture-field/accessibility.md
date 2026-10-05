
- **Role/trait**: Not implemented in source. No accessibility role, label,
  or title-element link — unlike the Key Command Row View
  (`adtoolkit://cookbook/ui/settings/rows/key-command-row-view`),
  whose sibling toggle control links to its label — appears anywhere in
  this component's own source; the view relies entirely on the platform's
  default accessibility exposure. The view is an interactive,
  focus-accepting control whose whole purpose is recording user input, and
  this file assigns it no accessibility role or label of its own; any such
  assignment is left entirely to the caller.
- **Label requirements**: Not implemented in source. This file
  sets no accessibility label of its own; a caller may assign one externally
  (accessibility identifiers, not labels, are assigned by the hosting row
  outside this file), but nothing in this component's own source guarantees
  a screen reader announces this control's purpose. This is the same gap
  as the Role/trait item above.
- **Announce state changes**: Not implemented in source. No accessibility
  change notification (or equivalent) accompanies the `isRecording`
  transition or a captured/committed/cancelled chord anywhere in source,
  so a screen reader user is not told the control entered or left
  recording mode.
- **Minimum tap target**: Not applicable to a touch-target threshold — this
  is a pointer/keyboard-driven control with no touch input path in source.
  Its actual click target is fixed at 22pt tall by a minimum of 132pt wide
  (see Min/Max size), matching this file's own layout constants, not a
  touch guideline.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. Every color it draws (background, accent and border, primary and placeholder text) is resolved at runtime from the active theme's palette, so whether any pairing meets a specific ratio (for example 4.5:1) depends on the colors each shipped theme supplies.

