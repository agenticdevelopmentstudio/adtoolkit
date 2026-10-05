
**Decision**: `onDismissed` is invoked synchronously inside `dismiss()`,
immediately after `willDismiss()` and before the fade-out animation
finishes, rather than from the animation's completion handler.
**Rationale**: Per the property's own doc comment, this lets "the owner drop
its reference without waiting out the fade" — an owner that releases its
only strong reference to the overlay the moment `onDismissed` fires does
not have to keep it alive for the 0.2s fade, since the fade-out's
completion closure only touches `self` via a weak reference.
**Approved**: pending

**Decision**: `dismiss()` sets `isDismissing = true` synchronously, before
calling `willDismiss()`, invoking `onDismissed`, or starting the fade-out
animation.
**Rationale**: Per the property's doc comment, "a reader can press Escape and
click in the same breath" — both `mouseDown` and `performKeyEquivalent`
route through the same `dismiss()`, and flipping the flag before anything
else runs is what makes the second of two near-simultaneous dismissal
gestures a guaranteed no-op rather than a race dependent on animation
timing.
**Approved**: pending

**Decision**: Dismissal on Escape/Return is implemented via
`performKeyEquivalent`, not `keyDown`, and the overlay never makes itself
first responder. (Applies to the AppKit/UIKit implementation.)
**Rationale**: Per the method's doc comment, AppKit offers every key-down to
this subtree via `performKeyEquivalent` before the responder chain sees it,
so Escape/Return dismiss without the overlay taking first-responder
status — which would otherwise cost the overlay's own content (e.g. a
scrollable transcript) the arrow keys and page keys it needs to stay
readable while presented.
**Approved**: pending

**Decision**: `mouseDown(with:)` unconditionally calls `dismiss()`, with no
check of what was clicked, relying entirely on the AppKit responder chain
to keep the call from firing when a control did claim the click. (Applies
to the AppKit/UIKit implementation.)
**Rationale**: Per the method's doc comment, this "works by not being
reached": a scroller, button, or selectable text a reader is interacting
with handles its own `mouseDown` and stops the event there, so this
override only ever runs for a press nothing else wanted — hit-testing
subviews manually would duplicate logic the responder chain already
provides.
**Approved**: pending

**Decision**: The backdrop's `blendingMode` is fixed to `.withinWindow` and is
not exposed as an `init` parameter the way `material` is. (Applies to the
AppKit/UIKit implementation.)
**Rationale**: Per the inline comment in `init`, what is being blurred is "the
view directly behind this one, not the desktop — this is a layer over a
window, not a window over a screen"; every overlay built on this class
shares that same relationship to its host, so there is no legitimate
caller-supplied alternative to expose.
**Approved**: pending

**Decision**: Main-actor isolation (see Platform Notes) is verified at compile time by the
Swift concurrency checker, not by an XCTest runtime assertion — a
non-main-actor call site fails to compile rather than throwing or asserting
at runtime. (Applies to the AppKit/UIKit implementation, which is written
in Swift.)
**Rationale**: `@MainActor` isolation is a type-system property; there is no
way to construct or call a member of `DismissibleOverlayView` from
off-actor code that still compiles, so the isolation check is executed as a
compile-fail check (e.g. a test target file that must not build) rather
than a normal test-runner assertion.
**Approved**: pending

**Decision**: While presented, the overlay does not trap Tab focus: only Escape, Return and keypad Enter are intercepted, and Tab can reach host controls underneath the backdrop.
**Rationale**: Nothing in the source restricts focus traversal to the overlay's content, and no keyboard-only pass has settled whether that is acceptable for the overlay's current host. Closing the gap would mean limiting the key-view loop to the overlay's subtree while presented and restoring it on dismissal.
**Approved**: pending

