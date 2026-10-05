
- **blurred-backdrop**: Component MUST add a blurred backdrop view, pinned
  to its own top, leading, trailing, and bottom anchors, using a
  within-window blending behavior and kept in its active (not inactive)
  appearance state.
- **backdrop-subview-order**: The backdrop MUST be added as this view's
  subview during construction, before any subclass's own initialization can
  add subviews of its own, so the backdrop is always the first (bottommost)
  subview.
- **backdrop-material-default**: Component MUST use its platform's default
  backdrop material when no `material` argument is supplied at
  construction.
- **backdrop-material-override**: Component MUST use the caller-supplied
  `material` value for the backdrop when one is passed at construction.
- **host-coverage**: Presenting the overlay in a host MUST add it as a
  subview of that host and constrain its top, leading, trailing, and
  bottom anchors equal to the host's corresponding anchors.
- **present-layout-order**: Presenting the overlay MUST set its opacity to
  0, then force the host and the overlay to lay out and draw
  synchronously, before starting the fade-in animation.
- **present-fade**: Presenting the overlay MUST animate its opacity from 0
  to 1 over `fadeDuration` (0.2 seconds).
- **dismiss-fade**: Dismissing the overlay MUST animate its opacity to 0
  over `fadeDuration` (0.2 seconds).
- **post-fade-removal**: Dismissing the overlay MUST remove it from its
  superview once the fade-out animation's completion handler runs.
- **dismiss-idempotency**: Dismissing the overlay MUST have no further
  effect on any call after the first — an observable consequence of
  `dismissing-flag-timing`, since dismissal returns immediately whenever
  `isDismissing` is already `true`.
- **dismissing-flag-timing**: Dismissing the overlay MUST set
  `isDismissing` to `true` synchronously, before running the pre-dismissal
  hook, invoking `onDismissed`, or starting the fade-out animation.
- **will-dismiss-timing**: Dismissing the overlay MUST run the
  pre-dismissal hook before starting the fade-out animation.
- **dismissed-callback-timing**: Dismissing the overlay MUST invoke
  `onDismissed`, when set, synchronously, immediately after the
  pre-dismissal hook and before the fade-out animation's completion
  handler runs.
- **default-will-dismiss**: The pre-dismissal hook MUST do nothing in the
  base implementation.
- **mouse-down-dismissal**: Component MUST dismiss itself whenever an
  unclaimed press reaches it directly (i.e. no subview claimed it first).
- **key-equivalent-subview-priority**: Component's key-equivalent handling
  MUST report the event as handled without dismissing itself when a
  subview already handled the event first.
- **escape-return-dismissal**: Component's key-equivalent handling MUST
  dismiss itself and report the event as handled when the event is Escape,
  Return, or keypad Enter, `isDismissing` is `false`, and no subview
  handled the event first.
- **non-dismiss-key-equivalents**: Component's key-equivalent handling MUST
  report an event that is not Escape, Return, or keypad Enter as
  unhandled, when no subview handled the event first.
- **key-equivalents-during-dismissal**: Component's key-equivalent handling
  MUST report a dismiss-key event as unhandled when `isDismissing` is
  already `true`.
- **open-subclassing**: The component's presentation, its pre-dismissal
  hook, and its press- and key-equivalent-handling entry points MUST all be
  overridable by a subclass, so a subclass can override presentation, add
  its own content above the backdrop, and extend dismissal handling.
- **will-dismiss-cleanup**: Subclasses SHOULD override the pre-dismissal
  hook to stop any timers, polling, or other ongoing work they own, since
  it runs once, before the fade-out begins, and the base implementation
  stops nothing on a subclass's behalf. A subclass with nothing running
  MAY leave the default no-op override in place; this is a recommendation
  for subclass authors, not a behavior this component can itself verify
  (see Design Decisions).
- **optional-dismissed-callback**: Callers MAY leave `onDismissed` as
  `nil`, in which case dismissal performs no additional callback work
  beyond the fade-out animation and removal from superview.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

