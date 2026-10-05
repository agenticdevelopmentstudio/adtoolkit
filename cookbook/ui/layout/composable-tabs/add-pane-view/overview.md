
The add pane sheet is presented behind arrange mode's Add button. It asks
two independent questions: which view to add (an "Add" choice built from the
entries the caller supplies) and which side of the current pane to put it on
(a "Where" choice among four fixed directions, defaulting to "Right"). These
are two separate choices rather than one flattened list (e.g. "Add Terminal
Below") because the second answer is the same four options whatever the
first one is — a cross product of eight or twelve items is a list to read
rather than a choice to make. Each offerable entry carries three fields: a
view identifier, a display name (the choice item's title), and an optional
icon shown alongside it. The direction is one of four fixed values: left,
right, above, below. Confirming with a valid selection dismisses the sheet
and then reports the chosen view identifier and direction to the caller;
canceling dismisses without reporting anything.

