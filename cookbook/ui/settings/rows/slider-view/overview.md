
The Slider View is a settings row: a title label and a slider in one
horizontal row, with no trailing caption (contrast with the sibling
captioned slider row
(adtoolkit://cookbook/ui/settings/rows/captioned-slider-view), which
adds a formatter-derived value label). The row is driven by a range view
model: the component sets the slider's range and value from the view
model at construction, writes the user's slider interactions back into
the view model's value, and re-synchronizes the label text and the
slider's range and value whenever the view model reports an external
change — including the range, which the sibling captioned slider row does
not re-apply after construction.

