
This component is a thin wrapper view around an internal vertical stack,
used to arrange a column of sibling views top-to-bottom within a settings
layout. It conforms to the same marker role every settings-row view in
this system adopts (its sibling horizontal stack view is the horizontal
counterpart, differing only in orientation and in whether its internal
stack is reachable by callers — see Design Decisions). The component has
no caller-configurable options: its only public constructor takes no
parameters, its inter-item spacing is fixed to the standard group-spacing
value, its internal stack view is exposed as a public, read-only
property, and its only other public member is an add-arranged-view
operation, which forwards to that same internal stack view.

