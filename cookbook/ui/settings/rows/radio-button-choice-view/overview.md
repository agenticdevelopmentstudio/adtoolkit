
The Radio Button Choice View is a settings row: a title label sitting above
a stack of native radio-button controls, one per entry in a choice view
model's ordered choices, each button's own title text set to that choice's
label. Unlike its sibling row views over the same choice view model (the
choice slider row, the popup menu choice row), this component does not use
the single horizontal [label, spacer, control] row layout its siblings
share; it composes two nested vertical/axis-driven groups instead — an
outer vertical group of [label, controls group], and an inner controls
group holding the radio buttons themselves, oriented by the constructor's
axis parameter (vertical by default). The row is driven by the view model:
it reflects the view model's title/value on construction and whenever the
view model reports an external change, and it writes the user's
radio-button selection back into the view model. A choice also carries an
optional symbol image, but this component never reads that field — only the
popup menu choice row, a sibling row over the same view model, renders it.

