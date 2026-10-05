
This component shows the content of the popover a breadcrumb's crumb opens: a
small, filterable, keyboard-navigable list of one directory's immediate
children. Typing in the filter field narrows the list to entries whose name
matches, with matched characters shown in bold; arrow keys, Return, and
Escape are handled by shared keyboard-navigation logic rather than bespoke
keyboard code. Selecting a file row invokes a selection callback with that
file's URL; selecting a directory row does nothing — this popover only opens
files, it does not browse further down the tree.

