
The font picker view pairs a title label with a font chooser button as one
settings row. Its title and font are driven by a caller-supplied font view
model: the row builds its label from the view model's title and shows the
view model's current font (with an "installed"/"not installed" qualifier)
on the button, keeps both in sync whenever the view model reports an
external change, and writes the font the user picks back into the view
model. The row is the binding and nothing else - the font-picker plumbing
lives once, in the font chooser button, so this row and any other caller
of that button cannot drift apart.

