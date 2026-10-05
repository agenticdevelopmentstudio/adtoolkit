
This is a terminal view — layered on the terminal-emulation library this
codebase uses — that decides, on every relevant view-hierarchy and
terminal-engine callback, whether its block-shaped text caret is drawn
filled or as a hollow outline. The underlying terminal-emulation
library's own cursor-style options have no hollow-block case among them,
and its own caret subview is not exposed for direct replacement, so this
view fakes the outline by drawing a border on the caret subview's own
layer rather than substituting a caret of its own — the underlying
library keeps ownership of the caret's position, size, and blink
animation. Two independent inputs decide the hollow-versus-filled state:
a per-instance appearance value the caller sets directly, and — only
when that appearance opts in via marking the active pane — whether this
view sits inside the pane that the active-pane tracker currently treats
as active for its window.

