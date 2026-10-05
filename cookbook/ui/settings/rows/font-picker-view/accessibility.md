
- **Role/trait**: Not observable beyond the platform's defaults - no
  custom accessibility role or element grouping call appears in source.
  The button carries its platform's native button role (see
  `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`); the label is a plain
  static-text control.
- **Label requirements**: The label and the button are laid out as sibling
  views in the same row, but source sets no accessibility linkage between
  them - confirmed by comparison with several sibling row controls in this
  system, which each link their control to its label, but this component
  does not do so for the button. The fixed accessibility identifier set in
  source is a UI-testing identifier, not an accessible name or label
  linkage. As a result, the screen reader announces only the button's own
  title text (e.g. "Menlo-Regular — 14 pt") when focus lands on it, not
  the row's title (e.g. "Terminal Font").
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The row label takes its color from the theme's primary-text role through the shared row-label factory, and when the row is disabled the label is drawn at a fixed 40% opacity (**dims-and-disables-the-row**), a value local to this component; the button keeps the platform's standard control chrome.
- **Announce state changes (e.g., loading, disabled)**: Source performs no
  explicit accessibility notification when the row's enabled state
  changes; the button's own enabled state is exposed automatically through
  its platform's native accessibility, but no proactive announcement is
  posted by this file. There is no loading state to announce (see
  States).
- **Minimum tap target**: Not applicable - this is a pointer/
  trackpad-driven composition on its source platform (no touch input path
  in source); the 44x44pt minimum is touch-platform guidance, not a
  pointer-interface requirement on the source platform.

