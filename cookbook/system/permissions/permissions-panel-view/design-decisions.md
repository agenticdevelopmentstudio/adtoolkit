
**Decision**: Cancel any refresh already in flight before starting a new
one (the cancel-and-replace pattern named in **latest-refresh-wins**),
rather than letting concurrent refreshes run to completion independently.
**Rationale**: Appearing, app reactivation, and a finished grant action
each ask for a refresh, and each row's status read is a cross-process
round trip they suspend on; left unserialized, whichever refresh *resumed*
last would win even if it was the older request — for example landing a
pre-grant snapshot after a post-grant one and leaving a row reading "Not
Granted" until the next activation. Cancelling the in-flight refresh
before starting a new one guarantees the most recently requested refresh
is the one that lands.
**Approved**: pending.

**Decision**: Schedule (not await) a refresh after the shared presenter's
grant flow returns from a row's action.
**Rationale**: Returning from system settings has already fired a refresh
through the activation notification, and the action-triggered refresh —
being requested later — is the one that should land; scheduling rather
than awaiting lets that later refresh cancel and supersede the
activation-triggered one via the same cancel-and-replace pattern.
**Approved**: pending.

**Decision**: Pin each row's width explicitly to the stack's width,
rather than relying on the stack's own alignment.
**Rationale**: A vertical stack does not stretch arranged subviews across
its width on this platform — alignment governs cross-axis *positioning*,
not fill — so without this constraint each row would size to its own
intrinsic content width instead of spanning the panel.
**Approved**: pending.

**Decision**: Observe `NSApplication.didBecomeActiveNotification` rather
than `NSWorkspace.didActivateApplicationNotification`.
**Rationale**: The intent is to refresh when *this* app becomes active
(for example, the user returning from System Settings), not on every app
switch system-wide, which the `NSWorkspace` notification would fire for.
**Approved**: pending.

**Decision**: Remove the notification observer explicitly in `deinit`,
even though the `NotificationCenter.addObserver(_:selector:name:object:)`
registration this component uses has been auto-zeroed on dealloc since
macOS 10.11.
**Rationale**: This guards against a view deallocated while still
attached to a window leaving a dangling registration; because the
observer is registered through the selector-based API rather than a
block-based one, removal here is defensive rather than strictly required
by the current minimum-deployment behavior.
**Approved**: pending.

