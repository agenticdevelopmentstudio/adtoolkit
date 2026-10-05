
The Captioned Slider View is a settings row: a title label, a slider, and
a trailing caption label in one horizontal row. The caption shows the
slider's current value rendered through a caller-supplied formatter (e.g.
"multiply by 100 and append a percent sign" or "append the letter s"), for
use when the slider's handle position alone doesn't identify the current
value. The row is driven by a range view model: the component reflects
the view model's title/min/max/value on construction and whenever the
view model reports an external change, and it writes the user's slider
interactions back into the view model's setting observer.

