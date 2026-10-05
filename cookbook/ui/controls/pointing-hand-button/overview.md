
This is a button that shows the pointing-hand cursor whenever the pointer
is within its bounds, whether or not its window currently has focus. Per
the source's own doc comment, a plain cursor-rect update alone is not
enough for the windows this toolkit puts on screen: a floating panel
beside the terminal the user is typing into is often not the focused
window, and the platform's cursor-rect mechanism only takes effect in the
focused window, so the one clickable thing in an unfocused list would
otherwise look like the surrounding text. This component combines the
ordinary cursor-rect update with an always-active hover-tracking mechanism
that sets the cursor directly from enter/move/exit callbacks, covering the
unfocused-window case, while the cursor rect still covers the ordinary
case where the platform resets the cursor on the way out.

