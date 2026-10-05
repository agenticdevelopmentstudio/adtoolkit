
**Decision**: Split "what to add" and "where to put it" into two independent
popups rather than one flattened list (e.g. "Add Terminal Below").
**Rationale**: Per the type's doc comment, the second answer (the four
directions) is the same regardless of the first, so a flattened list would
force the user to read a cross product of eight or twelve items instead of
making two small choices.
**Approved**: pending

**Decision**: Default the "Where" popup's selection to "Right" rather than
the first item ("Left") or no selection.
**Rationale**: Per the source comment, the pane the user is looking at is on
the left of a document more often than not, so placing the new pane to its
right is the least surprising default.
**Approved**: pending

**Decision**: Dismiss the sheet before invoking `onAdd` in the confirm
action, rather than invoking `onAdd` first.
**Rationale**: (AppKit) Per the source comment, `onAdd` re-parents view
controllers by splitting the pane; doing that while the sheet is still
presented would leave the sheet anchored to a window whose content has
already moved out from under it.
**Approved**: pending

**Decision**: Fix the direction list to the hardcoded order left, right,
above, below and reuse that same list both to populate the "Where" popup
and to map its selected index back to a direction.
**Rationale**: Per the source comment, a fixed order makes the popup read
the way the pane visually looks; reusing one list for both population and
index-mapping keeps the two in sync by construction rather than by
convention.
**Approved**: pending

**Decision**: Center-align the grid's rows instead of using `NSGridView`'s
default first-baseline row alignment.
**Rationale**: (AppKit) Per the source comment, a label baseline-aligned
against a popup sits high in it, which reads as a row that did not quite
line up; centering both views in the row instead makes the label and popup
look vertically aligned.
**Approved**: pending

**Decision**: Leave a defensive fallback to index 0 for the "Right" lookup,
even though the direction list is a hardcoded literal that always contains
"Right".
**Rationale**: Not explained in source; recorded here as an observed,
currently-unreachable defensive path, so other-platform implementations do
not need to reproduce a "what if Right is missing" branch.
**Approved**: pending

