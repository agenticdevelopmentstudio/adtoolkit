
- **Null/empty input**: Not applicable — this component defines no
  initializer, property, or configuration input of its own; the only
  inputs are the event arguments the platform supplies to the
  pointer-entered/moved/exited callbacks, which are never absent.
- **Boundary values**: This component passes `bounds` unmodified to both
  the cursor-rect registration and the hover-tracking region, with no
  minimum-size guard in source. A zero-size or not-yet-laid-out `bounds`
  is passed through as-is — the resulting cursor-rect/tracking behavior
  for a zero-area rect is the platform's own, not something this
  component special-cases.
- **Concurrent access**: Not applicable — the cursor-rect update, the
  hover-tracking registration step, and the pointer-event callbacks are
  all view-lifecycle methods that execute on the main thread only; the
  one hover-tracking-region property this component holds is read and
  written exclusively from those main-thread callbacks.
- **Error states**: Not applicable — this component has no dependency on
  network, database, or file-system access; cursor and hover-tracking
  management cannot fail in the way this source uses them.
- **Offline/disconnected state**: Not applicable — this component
  performs no networking.
- **Unfocused window with pointer inside bounds**: This is the case the
  component exists to handle. Because tracking is configured to remain
  active regardless of window focus rather than only within the focused
  window (per the source's own comment), the pointer-entered/moved/exited
  callbacks continue to fire even while the button's window does not have
  focus, so the pointing-hand cursor still appears — unlike a plain button
  relying on the cursor-rect mechanism alone, whose cursor rect the
  platform only honors in the focused window.
- **Exit into a cursor-owning sibling**: The pointer-exited callback
  unconditionally resets to the default arrow cursor (see conformance
  vector pointing-hand-button-007), with no check on what the pointer
  moved onto. If the pointer exits this component's bounds directly into
  a sibling view that manages its own cursor (for example, a text view
  showing a text-insertion cursor), this handler's reset can momentarily
  overwrite that sibling's cursor before the sibling's own tracking or
  cursor-rect mechanism re-asserts it. This is a known limitation of the
  source's unconditional reset, not a coordinated hand-off between views.

