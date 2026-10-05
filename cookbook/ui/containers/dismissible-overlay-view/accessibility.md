
- **Role/trait**: Not explicitly set — the source sets no accessibility
  role override anywhere; the platform's own default view role applies
  unmodified.
- **Label requirements**: Not implemented in source. Nothing in this
  component sets an accessibility label or description on itself or the
  backdrop, so a screen reader user gets no announced description that
  this is a dismissible overlay or of how to dismiss it (click anywhere
  unclaimed, Escape, or Return); any such label would have to come from a
  subclass or caller, and none of the toolkit's current subclasses supplies
  one.
- **Announce state changes**: Not implemented in source. Neither
  presenting nor dismissing the overlay posts an explicit accessibility
  notification when it appears or disappears, so no notification is posted
  at either transition — only whatever the platform's own default
  view-hierarchy handling provides applies.
- **keyboard-focus-containment**: The overlay MUST NOT be relied on to contain keyboard focus. Key-equivalent handling intercepts only Escape, Return, and keypad Enter; Tab traversal is not restricted to the overlay's own content while it is presented, so a keyboard user can Tab onto a host control beneath the backdrop.
- **Minimum tap target**: Not applicable in the small-target sense — per
  `mouse-down-dismissal` and `host-coverage`,
  the dismiss gesture's target is the overlay's entire frame, which itself
  covers the host entirely; there is no small tap target to size.
- **Minimum contrast ratio**: Not applicable to this base view — it renders
  no text or foreground content of its own (see Appearance). Contrast is
  the responsibility of whatever content a subclass adds above the
  backdrop, which is out of scope for this recipe.

