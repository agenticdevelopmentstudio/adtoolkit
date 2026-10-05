
- **Null/empty input**: The font parameter given to the component is
  optional and `nil` is an explicit, handled case (falls back to the
  system font — see **system-font-fallback**). The title parameter is a
  non-optional string; an empty string is drawn as an empty title with no
  crash — already covered by **caller-supplied-title**, which sets the
  title to whatever is passed verbatim, empty or not.
- **Boundary values**: An explicit fixed width is an unconstrained numeric
  value passed straight into the width constraint with no clamping or
  validation. A zero or negative width is passed through unchanged and
  produces a zero-width or layout-unsatisfiable constraint; this is not
  validated (current behavior) — the component performs no
  bounds-checking of its own on the width.
- **Concurrent access**: Not applicable — the component is confined to the
  UI thread, so all construction and mutation is serialized to that
  thread; there is no code path by which two threads mutate the same
  instance simultaneously.
- **Error states**: Not applicable for giving the component a font/title
  or for the picker wiring — every operation in this file is a
  synchronous, non-throwing call; no error-producing path appears in
  source.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking of its own.
- **Multiple instances sharing one active recipient**: The platform's
  font-picker registration holds one active recipient at a time. WHEN two
  instances of this component exist and both have opened the picker, the
  most recently opened one owns that registration; the earlier one's later
  removal is guarded by an identity check against the current registration
  and so correctly does nothing, leaving the picker's current registration
  untouched — already covered by
  **releases-picker-registration-on-removal**, whose "still the active
  recipient" condition is exactly this identity check.
- **Picker opened before any font is ever chosen**: Opening the
  font-selection UI on a freshly-constructed, never-given-a-font button
  does not crash and seeds the picker with the system font at the
  platform's default point size (which is not the sample size) — already
  covered by **opens-font-picker**'s fallback-seed behavior.

