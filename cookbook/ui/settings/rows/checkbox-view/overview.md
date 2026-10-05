
The Checkbox View is a settings row: a title label leading and a toggle
trailing, in the same row shape a system settings surface uses for a boolean
setting. Despite the name, the control it draws is a switch, not a checkbox
button — the concept exists because a checkbox puts its control on the left,
the one row shape that cannot line up with the popups, steppers, and sliders
beside it in the same settings card (see Design Decisions). The row is driven
by a boolean view model: the view reflects the view model's title/value on
construction and whenever the view model reports an external change, and it
writes the user's switch interactions back into the view model's setting
observer.

