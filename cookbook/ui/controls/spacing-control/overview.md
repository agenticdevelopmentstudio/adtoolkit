
The control draws a small diagram of the thing being spaced and lets the
user edit the numbers that shape it. It has two styles, same size, same
chrome, same behavior: `frame` draws one view inside its container with the
four edge insets (`top`, `leading`, `bottom`, `trailing`) that separate them;
`paneDividers` draws four panes and the two gutters between them
(`betweenColumns`, `betweenRows`). Every number carries a text field, a
stepper, and a pair of arrow buttons standing on the line they move —
pointing the direction that line travels when pressed — plus a draggable
handle wrapping that pair so the same line can be dragged directly. A
"Reset" control zeroes only the numbers the current style shows. The
control knows nothing about settings or persistence: it holds a spacing
value and reports user-driven changes through an `onChange` callback; a
separate settings-binding layer, out of this recipe's scope, ties a control
to persisted settings values so it can be dropped into a settings panel in
one expression. See Platform Notes for where that binding and its concrete
callers live in the source implementation.

Use this ingredient wherever a settings surface needs to let a user tune
one or more edge insets, or the gutters of a pane grid, with a control that
shows *which* number changes *which* edge without a separate diagram or a
column of unlabeled fields.

