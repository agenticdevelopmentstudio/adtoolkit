
The Swatch Grid View is a display component from the composable settings
window's system integration that displays a caller-supplied array of
colors as a grid of fixed-size color swatches, wrapped into rows of a
fixed column count. Per its doc comment, it generalizes the ad-hoc
swatch/ANSI grid the terminal profiles view used to build inline. Unlike
sibling rows such as the color picker row
(adtoolkit://cookbook/ui/settings/rows/color-picker-view), it is
purely a display component: it exposes one mutator, a color-replacement
operation, and contains no interactive-control code of any kind.

