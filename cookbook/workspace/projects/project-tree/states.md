
Not applicable — this is a tree-building data structure and algorithm, not a
visual component. The tree-building operation has no runtime state machine
of its own: it is called anew, synchronously, every time the project
browser needs a fresh tree; nothing in this file remembers a previous
call's result.

