
The Horizontal Stack View is a thin wrapper used to arrange a row of
sibling views left-to-right within a settings layout. It fulfills the same
settings-row-view contract as its siblings in this system; the sibling
Vertical Stack View recipe is its vertical counterpart, differing only in
orientation and in that its inner stack is exposed as a public property
rather than kept private. The Horizontal Stack View has no
caller-configurable options: it takes no construction parameters, its
inter-item spacing is fixed to the standard group-spacing value, and its
only other public operation adds a view to the arranged row.

