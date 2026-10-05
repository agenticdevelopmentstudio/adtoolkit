
The Choice Slider View is a settings row: a title label, a discrete slider
whose ticks each correspond to one entry in a choice view model's ordered
list of choices, and a trailing label showing the current choice's name.
The slider snaps to ticks only — it never represents a value between two
choices. The row is driven by the choice view model: the view reflects the
view model's title/value on construction and whenever the view model reports
an external change, and it writes the user's slider interactions back into
the view model's setting observer. A choice also carries an optional image
identifier, but this component never reads that field — only a sibling row
over the same view model renders it.

