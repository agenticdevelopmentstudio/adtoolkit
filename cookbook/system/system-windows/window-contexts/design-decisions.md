
**Decision**: Inactive windows are parked 30,000 points left of the leftmost screen instead of being minimized or hidden.
**Rationale**: Per the `parkingMargin` doc comment, a parked window "can never land on a real screen (even on multi-monitor layouts)", and moving keeps the window's app, Space, and size intact, so restoring is a single set-frame; y is kept so a window restores in place.
**Approved**: pending

**Decision**: (Apple platforms) A live frame is captured into `savedFrame` only while it overlaps a screen horizontally.
**Rationale**: Per `captureFrameIfOnScreen`, a parked position or an OS-clamped park move "can never be persisted as the restore target"; the horizontal-only test avoids mixing CoreGraphics top-left y with AppKit bottom-left y.
**Approved**: pending

**Decision**: (Apple platforms) On load, a persisted window ID is invalidated when it is missing only if its app has a live window, and always when it now belongs to another app.
**Rationale**: `CGWindowID`s are not stable across restarts; the comment in `reconcilePersistedWindowIDs` explains that an app with zero live windows "may still be mid-launch", and clearing its IDs would orphan valid windows.
**Approved**: pending

**Decision**: Deleting the active context restores every context's windows, not just the deleted one's.
**Rationale**: With no active context nothing should stay parked; the comment in `deleteContext` notes that otherwise "the other contexts' windows are stranded off-screen with no way back."
**Approved**: pending

**Decision**: Switching to the already-active context re-shows its windows rather than throwing `alreadyActiveContext`.
**Rationale**: The source treats a repeat switch as a request to make the context's windows visible; `alreadyActiveContext` and `noActiveContext` remain in the error enum but nothing raises them.
**Approved**: pending

**Decision**: Custom heuristic rule changes write to disk before updating memory and the registry, while context changes update memory first and then persist.
**Rationale**: The `addCustomHeuristicRule` doc comment calls out "no phantom rule" after a failed write; context operations instead keep the in-memory change and surface `persistenceFailed`, so a failed write leaves memory ahead of disk until the next successful persist.
**Approved**: pending

**Decision**: (Apple platforms) Writes are serialized with an inter-process `flock` on `<root>/.lock`, reads are unlocked, and each file is replaced atomically.
**Rationale**: The store's doc comment names concurrent write corruption as the risk and keeps reads unlocked "for performance"; per-file atomic replace keeps each file whole for a concurrent reader.
**Approved**: pending

**Decision**: Own windows are excluded by process ID rather than by `selfAppName`.
**Rationale**: Per `isOwnWindow`, matching the owner name "silently fails when a host's display name differs from its process name"; the PID is host-name-independent.
**Approved**: pending

**Decision**: (Apple platforms) Test environments disable notifications, observation, and seeding, and the notification step checks the bundle identifier first.
**Rationale**: The source notes `UNUserNotificationCenter.current()` "crashes outside of a bundled app"; each switch is separate so a host can disable one without the others.
**Approved**: pending

**Decision**: `reconcileBehavior` is stored but not consulted by launch reconciliation.
**Rationale**: The model persists the setting for a host's settings UI; `performLaunchReconciliation()` implements the `prompt` behavior unconditionally, so honoring `auto` or `ignore` is the host's responsibility.
**Approved**: pending

**Decision**: Saving all contexts is atomic per file only; a mid-way failure leaves disk partially updated.
**Rationale**: It stands today because there is no rollback or journal. Closing it needs a decision on whether the atomic contract spans files (a temp-directory swap) or only each file, and a failure-injection test.
**Approved**: pending

**Decision**: Restore and un-park failures are silent.
**Rationale**: It stands today because frame-set results are discarded. Closing it needs a decision on whether restore failures are logged, counted or surfaced, and a test.
**Approved**: pending

**Decision**: Window assignment is unvalidated, so one window can back two snapshots.
**Rationale**: It stands today because only add-window-snapshot validates. Closing it needs a decision on whether a window may back two snapshots and, if not, which assignment wins, and a test.
**Approved**: pending

**Decision**: Observer events are handled as independent units of work with no stated ordering.
**Rationale**: It stands today because ordering relies on the scheduler. Closing it needs confirmation that the observer delivers on a single thread and that enqueued work runs first-in-first-out, or serializing events through one queue.
**Approved**: pending

