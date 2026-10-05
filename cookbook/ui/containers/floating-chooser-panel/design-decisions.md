
**Decision**: Guard reentrancy with an owned `isDismissing` boolean rather
than inferring "already closing" from window state.
**Rationale**: Closing the key window resigns key *before* the window is
ordered out, so `windowDidResignKey` re-enters mid-close; the platform's
own window state has not finished updating at that point, so only a
controller-owned flag can distinguish a resignation that is part of this
close from one caused by the user switching away. (Applies to the AppKit
implementation.)
**Approved**: pending

**Decision**: Keep `.closable` in the style mask (which puts a close button
in the frame) and then hide the close/miniaturize/zoom buttons explicitly,
rather than omitting `.closable`.
**Rationale**: `.titled` is required for the standard frame and for
`.fullSizeContentView` to draw hosted content up into the title-bar band;
every way out of the panel already goes through `close()` via Escape,
click-away, or accepting a result, so the traffic-light buttons have
nothing left to do and are hidden rather than removed from the style mask.
(Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Call `NSApp.activateUnlessQuiet()` before `showWindow`/
`makeKeyAndOrderFront`, not after.
**Rationale**: A chooser can be opened by a system-global shortcut while
another app is frontmost; activating after taking key would let the
platform hand key back to whichever of this app's windows held it last,
closing the just-opened panel immediately once focus-loss dismissal runs.
(Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Set `isReleasedWhenClosed = false`.
**Rationale**: `close()` runs on every dismissal, including a plain focus
loss; a chooser is expected to reopen as the same instance rather than
being rebuilt from scratch each time, so the window and its controller
must survive being closed. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Position the panel relative to the screen under the mouse
pointer, not the key window's screen.
**Rationale**: The chooser can be invoked with no window of this app on
screen at all (a system-global shortcut, or an extension request), so
there may be no key window's screen to anchor to; the pointer is the one
reliable proxy for the screen the user is currently looking at. (Applies
to the AppKit implementation, though the underlying rationale — anchoring
to wherever the user's attention is, absent a focused window — carries to
any platform's port.)
**Approved**: pending

**Decision**: Positioning does not clamp the panel to the visible area: a content rect taller than the visible height less the 20% top offset yields a negative vertical origin.
**Rationale**: The origin is computed from the window's frame and the visible frame with no bounds check, and every current extending component sizes itself well inside a normal screen. Closing the gap requires deciding whether the clamp belongs in this base class or in each extending component's sizing.
**Approved**: pending

