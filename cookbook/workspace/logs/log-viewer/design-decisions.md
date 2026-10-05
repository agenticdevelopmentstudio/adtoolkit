
**Decision**: Route both theme-palette changes and controller state changes
through the same status-indicator refresh, rather than painting theme
colors in a separate observer callback.
**Rationale**: The source comment states the status dot's color and the pause
button's title both depend on controller state, so "a theme change and a
state change have to land in the same place or one overwrites the other
with the previous theme's colours."
**Approved**: pending

**Decision**: (AppKit/macOS) Use `ThemedSecondaryButton` for Pause and Clear
instead of `ThemedButton` (the accent-filled pill button).
**Rationale**: The source comment states two accent-filled pills in a toolbar
"would claim more emphasis than a log's controls deserve," so lower-emphasis
secondary styling was chosen deliberately.
**Approved**: pending

**Decision**: (AppKit/macOS) Use `ThemedSeparatorView` for the toolbar/log
divider instead of an `NSBox` separator.
**Rationale**: The source comment states an `NSBox` separator "draws a system
hairline, which is the one line in this window the palette could not
reach," so a themed view was substituted to keep the divider on-palette.
**Approved**: pending

**Decision**: Enforce `minimumContentSize` as constraints on the root
view's own width/height.
**Rationale**: The source comment states the hosted log view has no
intrinsic width, so without a floor the window collapses the component's
view to its fitting size after its async layout pass — "a 1pt-wide
window."
**Approved**: pending

**Decision**: (AppKit/macOS) Give the pause/clear buttons no explicit
width/height constraint.
**Rationale**: The source comment states `ThemedSecondaryButton` measures the
title it is about to draw, in the theme's own button font, and grows past
its stock 68×22 minimum rather than clipping at a large size scale.
**Approved**: pending

**Decision**: The status dot and status label colors resolve from whichever theme palette is active, and the component performs no contrast check of its own; no contrast calculation appears in the logging window sources.
**Rationale**: Whether a given theme's resolved pair meets a target ratio (3:1 for the non-text dot, 4.5:1 for the caption-sized label) can only be judged per palette. Closing the gap means auditing each concrete palette's resolved colors against the platform's contrast guidance, or adding a palette-level contrast test.
**Approved**: pending

