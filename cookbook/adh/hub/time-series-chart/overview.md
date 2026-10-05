
The Time Series Chart draws a handful of series as thin lines across a shared
sequence of x positions (days, weeks, months), all on ONE y scale. Two measures
of different scale belong in two charts, never on a second axis. A crosshair
tooltip reads every series at the hovered x position, and a legend names the
series once there are two or more, so a series is never identified by colour
alone. A missing value is a gap in the line, never a zero. The chart draws at
most four series, each coloured by its position in the series list from a fixed
categorical palette that is stable across themes; a fifth series is refused
rather than given a generated hue a reader could no longer tell apart (the
caller folds the tail into an "Other" series instead). The plot's width follows
its container; only the height is a parameter.

