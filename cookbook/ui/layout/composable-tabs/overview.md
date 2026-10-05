
The composable tabs split tree is the recursive building block of a project
tab's pane layout. Each instance is either the tab's root or one node of a
binary tree nested beneath it: it holds at most two children — panes, or
further nested split nodes — laid out along an axis (horizontal or vertical).
The tree's shape and each node's share of its split (a thickness fraction)
are captured to and rebuilt from a value-type layout node, so a project's
stored layout can be persisted, restored, and mirrored across tabs. On top of
the tree itself, the split node also acts as the pane host — the object a
pane calls to close, minimize/restore, or zoom itself, and the one that
resolves those requests against the layout spec and the live split items.

