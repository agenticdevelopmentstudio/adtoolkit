
The active pane tracker is a single, app-wide tracker that tracks,
independently for each open window, which composable-tabs pane the user is
currently working in — the one they last clicked in, or, with the
pointer-follows setting on, the one under the pointer. The platform provides
no "the input focus changed" notification of its own, and a pane's own
content intercepts pointer events before a pane could see them itself, so
the tracker installs one pointer-event monitor for the whole app (primary
click, secondary click, pointer move) instead of every pane installing a
monitor of its own, and answers "which pane is this point in" with one hit
test rather than a second implementation of it living in a tracking area.

This ingredient also covers the pane backdrop view — a pane's backdrop that
draws the "this is the pane you are working in" border. It is one view — not
an overlay — so the border can never end up under the pane's own content,
and it registers its arrival and departure with the tracker as it moves in
and out of a window, and repaints whenever the tracker, the window's focus
state, or the highlight setting changes.

Neither part renders or exposes anything else: no title, no icon, no
interactive control of its own. The chrome a pane wears beyond this backdrop
(title bar, gear menu, content identifier) belongs to the pane's own view
controller, not to this component, and is out of scope for this ingredient.

