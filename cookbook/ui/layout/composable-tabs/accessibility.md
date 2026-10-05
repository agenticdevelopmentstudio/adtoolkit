
- **Role/trait**: Not explicitly set in source. The underlying split control
  exposes its platform's own default split-view accessibility role and
  divider semantics; this component overrides no accessibility API of its
  own.
- **Label requirements**: Not applicable at this level — no accessibility
  label or identifier is assigned to the split view, a divider, or an item in
  this source; a pane's own accessible content is that pane's own concern
  (each pane is a separately hosted child component with its own view).
- **Announce state changes**: Not implemented in source. A zoom, a
  minimize/restore, a split, a remove, or a move all change which panes are
  visible and how much space each has, but nothing in this source posts an
  accessibility notification when any of these happen; the refusal path even
  for a genuinely-blocked action is a plain audible beep, not a
  screen-reader-readable message. A screen reader user is not told a pane
  appeared, disappeared, or changed size, and hears nothing until navigating
  back into the split.
- **non-pointer-resize**: A divider's thickness fraction changes only through a pointer drag (plus the widened hit-test area from `widen-divider-grab-area`). The component provides no method or command that lets a keyboard-only or switch-control user change a thickness fraction without a pointer, and it does not add keyboard behavior beyond what the platform's split view supplies by default. Touch tap-target minimum guidance does not apply: this is a pointer-driven control.

