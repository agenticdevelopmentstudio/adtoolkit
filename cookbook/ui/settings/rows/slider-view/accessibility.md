
- **Role/trait**: Not observable beyond the platform's defaults — no
  explicit accessibility-role call appears in source. The slider and the
  label each carry the platform's built-in accessibility role (slider,
  static text) automatically.
- **Label requirements**: The label and the slider are laid out as
  sibling views in the same row, but source links no accessible name from
  the slider to the label text — confirmed by comparison with sibling row
  views in the same directory: the checkbox row, the number field row,
  and the popup menu choice row each link their control to the label, but
  this component does not do so for the slider. Without that link, a
  screen reader announces the slider on its own with no reference to the
  row's title when focus lands on it.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself (see
  States); there is no state transition to announce.
- **Minimum tap target**: Not applicable — this is a pointer/
  trackpad-driven control composition (no touch input path in source);
  the 44×44pt minimum is touch guidance, not a pointer-interface
  requirement.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label's color comes from the theme's primary-text role through the shared row-label factory, and the slider draws in the platform's standard control style, so contrast is whatever the active theme and platform resolve.

