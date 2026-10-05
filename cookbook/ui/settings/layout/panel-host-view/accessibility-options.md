
- **Reduce Motion**: Not applicable — the source contains no animation or
  transition of any kind. Content swapping and help-button refresh are
  both synchronous property and child-view assignments, not a motion
  effect.
- **Increase Contrast**: Not applicable in this file — the help button's
  colors come entirely from the active theme palette (accent-color role /
  secondary-text-color role); if Increase Contrast should raise either
  color's contrast, that is the palette/theme system's responsibility, not
  this component's. Whether these colors reach an adequate ratio is the
  **minimum-contrast-ratio** and its Design Decision, tracked once under
  Accessibility above.
- **Differentiate Without Color**: Supported — the help-visible and
  help-hidden states are distinguished by both the button's icon shape
  (filled vs. outlined) and its tint color
  (**help-button-icon-reflects-visibility**,
  **help-button-tint-reflects-visibility**), so color is never the sole
  signal.

