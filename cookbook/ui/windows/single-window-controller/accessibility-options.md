
- **Reduce Motion**: Not applicable — the class has no animation code path;
  window moves/resizes it performs (the fit-to-content operation, frame
  restoration) are instantaneous frame assignments, not animated
  transitions.
- **Increase Contrast**: Not applicable — the base class sets no colors of
  its own beyond HUD transparency, which is a deliberate translucency effect
  rather than a contrast-relevant foreground/background pairing.
- **Reduce Transparency**: Not applicable to the base (non-HUD)
  configuration, since no window built without the HUD-configuration
  operation has any translucency to reduce. For a HUD-configured window, the
  set-transparency operation sets translucency unconditionally from the
  caller-supplied value; the class does not observe the system's
  reduce-transparency accessibility setting, so a HUD window's opacity is
  never re-clamped toward opaque when the system setting is enabled.

