
The Progress View is a settings row wrapping a single progress indicator,
pinned edge-to-edge inside itself. It is driven entirely by a progress view
model: a subscription to the view model's progress value (present or
absent, where absent means indeterminate per the view model's own doc
comment) flips the indicator between a determinate bar showing a numeric
value and an animating indeterminate bar every time that value changes, for
as long as the view exists.

