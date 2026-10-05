
- **Null/empty input** (SHOULD/MUST): `onDismissed` defaults to `nil`, and
  dismissing an instance with `onDismissed == nil` proceeds identically
  minus the callback (MUST, per `optional-dismissed-callback`). `material`
  is a required, typed parameter with a default value, so
  there is no null/empty case for it to guard.
- **Boundary values** (MUST): the set of dismiss keys is a fixed
  three-value set (Escape, Return, keypad Enter); a key event either is or
  is not a member — there is no partial match, range, or near-miss
  behavior (per `escape-return-dismissal` / `non-dismiss-key-equivalents`).
  `fadeDuration` is a single fixed 0.2s value with no configurable minimum
  or maximum.
- **Presenting the overlay on a momentarily zero-sized host**: because
  layout and drawing are forced before the fade starts (per
  `present-layout-order`), a host that is still zero-sized at the moment of
  presenting produces a zero-sized first frame; once the host is later
  given a real size, the overlay's own edge-pinned constraints (per
  `host-coverage`) resize it to match — nothing in source detects or
  defers the zero-sized first frame itself.
- **Dismissing an instance never presented**: removing a view with no
  superview is a harmless no-op; the pre-dismissal hook and `onDismissed`
  still fire (per `will-dismiss-timing` and `dismissed-callback-timing`) —
  dismissal has no guard requiring the view to have been presented first.
- **Concurrent access**: Not applicable — this component is confined to a
  single thread of execution for its entire lifetime, so there is no path
  for two threads to call present/dismiss on the same instance
  simultaneously. See Platform Notes for how that
  confinement is enforced, including how the one non-isolated closure in
  source (the fade-out completion handler) re-establishes that confinement
  before touching itself.
- **Error states (dependency/network failure)**: Not applicable — the
  source performs no network call, database access, or file I/O; every
  operation (mutating opacity, adding/removing subviews, invoking
  closures) is synchronous, in-process, and non-throwing.
- **Offline/disconnected state**: Not applicable — no networking exists
  anywhere in this file.
- **Escape and an unclaimed click arriving in the same runloop turn**
  (MUST): because `isDismissing` flips to `true` synchronously on the first
  call to dismiss (per `dismissing-flag-timing`), whichever gesture is
  processed second sees `isDismissing == true` and is a guaranteed no-op —
  this is not a race that depends on animation timing.
- **A second overlay presented on top of the first** (MUST, per the
  concept's own rationale of "a message expanded over a conversation"):
  because key-equivalent handling offers the event to subviews first (per
  `key-equivalent-subview-priority`), the topmost overlay — being the
  nearer subview in the responder chain — is the one Escape dismisses, not
  the one underneath it; see `dismissible-overlay-025` for the two-overlay
  vector this rests on.

