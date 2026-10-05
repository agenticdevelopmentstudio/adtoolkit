
- **Role/trait**: Not customized beyond the platform's own defaults — no
  explicit accessibility role override appears anywhere in source. Each
  radio button produced by the platform's own factory carries the
  platform's built-in radio-button accessibility role and reports its own
  visible title text (the choice's label) as its accessible name
  automatically — unlike a bare, title-less control, each button here is
  already individually named.
- **Label requirements**: Not implemented in source. Source sets no
  accessibility API at all on the label, the controls group, or any radio
  button — no accessible-name link, no accessibility group role, no child
  linkage tying the heading label (e.g. "Theme") to the set of radio
  buttons beneath it as one named group. This is confirmed by comparison
  with the checkbox row, a sibling row, which does link its single
  control's accessible name to its label; a screen reader has no
  source-declared link between the heading's text and the radio-button
  group, so each button's own visible title is the only accessible name
  it reports.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself in source
  (see States); a selection change is announced by the platform's own
  native accessibility value reporting when the selected state changes,
  which this component does not override.
- **Minimum tap target**: Not applicable — this is a pointer/
  trackpad-driven control composition (no touch input path in source); the
  44×44pt minimum is touch guidance, not a pointer-interface requirement.
  This component sets no reduced control size on any radio button, so each
  keeps the platform's regular system click-target metrics.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The heading label takes its color from the theme's primary-text role through the shared row-label factory, and the radio buttons draw in the platform's standard control style, so contrast is whatever the active theme and platform resolve.

