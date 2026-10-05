
The arrange overlay is a view that a composable-tabs pane shows in place of
its normal content while the enclosing window is in arrange mode. It dims
the pane's content behind a scrim and centers one small toolbar over it —
Add, Remove, a Move menu, and Done — plus the pane's name, so the user
always knows which pane they are about to rearrange even though its content
is unreadable underneath. The scrim is a real subview with a translucent
background rather than an alpha applied to the content, so it can also
swallow pointer clicks meant for that content, while still letting an
unhandled click travel up to the pane's background view so clicking a
dimmed pane still selects it. The pane's own view controller installs and
removes an instance of this view as arrange mode toggles for the window,
and re-reads the can-add, can-remove, and available-directions callbacks by
refreshing availability whenever the tab layout changes.

