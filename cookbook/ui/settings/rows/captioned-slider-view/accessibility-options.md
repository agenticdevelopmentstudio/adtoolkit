
- **Reduce Motion**: Not applicable — source contains no animation or
  transition call; every state change is an instantaneous property
  assignment.
- **Increase Contrast**: This component itself sets no custom color; both
  labels get their color from theme color roles (primaryText for the
  title, secondaryText for the caption), not from unstyled control
  defaults (see Appearance → Foreground/Text). The theme's palette does
  not read the system's Increase Contrast signal, so the row's contrast
  does not change when a user turns that system setting on; whatever the
  active theme's colors resolve to is what both labels show either way.
- **Differentiate Without Color**: Not applicable — the current value is
  communicated through the slider's thumb position and the caption's
  text, not through any color-only signal; no color-coded state exists in
  source.

