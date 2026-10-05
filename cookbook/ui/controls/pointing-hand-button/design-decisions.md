
**Decision**: The pointing-hand cursor is set from both the cursor-rect
update and an always-active hover-tracking region's enter/move/exit
handlers, rather than from the cursor-rect update alone.
**Rationale**: Per the source's own doc comment, cursor rects are honored
by the platform only in the focused window, but this toolkit places
clickable controls in windows that are not focused (a floating panel
beside the terminal the user is typing into); the always-active
hover-tracking region covers that case, "and the cursor rect still covers
the ordinary one, where AppKit resets the cursor for us on the way out."
(Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: The hover-tracking registration step removes any existing
hover-tracking region before adding a new one, rather than leaving prior
regions registered.
**Rationale**: Traceable to the explicit `if let hoverArea {
removeTrackingArea(hoverArea) }` guard in source; without it, repeated
calls to `updateTrackingAreas()` — which AppKit can invoke whenever the
view's geometry changes — would accumulate duplicate, stale-rect tracking
areas. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: The disabled (not-enabled) case is left unaddressed in this
recipe rather than described as suppressing the pointing-hand cursor.
**Rationale**: None of the source's five overridden methods reads the
enabled state, so no behavior actually differs between an enabled and a
disabled button. This is recorded in States as a plain fact about
disabled-state cursor behavior, rather than silently normalized to the
idealized behavior a reader might expect. (Applies to the AppKit
implementation.)
**Approved**: pending

