
- Reduce Motion: Not applicable — this component's source contains no
  animation or transition call. Content replacement and theme recoloring
  are both synchronous property and color assignments, not a motion
  effect.
- Increase Contrast: Not applicable in this file — every color comes from
  the active `SemanticPalette` (`windowBackgroundColor`, `primaryTextColor`);
  if Increase Contrast should raise these colors' contrast, that is the
  palette's responsibility, not this view's. The open question on
  minimum-contrast-ratio is tracked once, under Accessibility above.
- Differentiate Without Color: Not applicable — the view conveys no state
  through color; it renders a fixed heading and caller-supplied topic text,
  with no color-coded meaning to differentiate.

