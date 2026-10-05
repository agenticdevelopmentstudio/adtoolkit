
The Popup Menu Choice View is a settings row: a title label leading and a
borderless popup control trailing, matching System Settings' card-drawn
popup convention where the current value reads as secondary text followed
by a chevron pair, with no bezel boxing the control a second time inside a
card that already provides the surface. The popup's menu items are built
once, at construction, from the view model's ordered list of choices — each
item's title, value, and optional symbol image come from one choice. The
view reflects the view model's title/value on construction and whenever the
view model reports an external change, and it writes the user's menu
selection back into the view model.

