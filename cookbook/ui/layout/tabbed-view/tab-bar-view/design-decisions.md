
**Decision**: `startInset` defaults to `endPadding` (`8pt`) rather than `0`.
**Rationale**: Per the source's own doc comment, this is "where the first
item begins... `endPadding` unless a host says otherwise. A host whose
workspace has chrome of its own can line the first tab up with it, and the
bar stays ignorant of what it is lining up with" — the default keeps a bar
with no special host chrome visually consistent with its own trailing-end
inset. (AppKit/UIKit.)
**Approved**: pending

**Decision**: `TabButton`'s cross-axis pin (`pinCrossAxis(_:)`) is applied
only on a vertical bar, while a `.viewController` item's `TabItemHostView`
gets it unconditionally, on every edge.
**Rationale**: Per the source's own comments, a vertical bar's buttons "fill
the bar's interior width so labels and close buttons line up flush," while a
hosted item's content "reports no intrinsic size" on the cross axis and "has
to be told to fill the bar's interior" regardless of orientation, since only
its length along the stack's main axis is otherwise constrained (via
`preferredContentSize`). The asymmetry is a direct consequence of `TabButton`
having its own intrinsic cross-axis size (from its label and padding) on a
horizontal bar, and a hosted controller's view not having one on either axis.
(AppKit/UIKit.)
**Approved**: pending

**Decision**: `rebuildButtons()` tears down a superseded hosted controller's
view only when that view's current superview is still this bar's own
(now-stale) `TabItemHostView`.
**Rationale**: Per the method's own comment, a cross-edge move "reparents the
controller's view onto the new bar's wrapper before the old bar notices the
id is gone from its own items," so tearing it down unconditionally there too
"would rip the view out of the new bar's display and cut the controller's
`preferredContentSizeDidChange` routing." (AppKit/UIKit.)
**Approved**: pending

**Decision**: `TabButton.accessibilityPerformPress()` always selects the
tab, even though a physical click can instead route to the close action.
**Rationale**: The source's own comment reads "`AXPress` selects the tab, the
same call `mouseDown` makes — so a driven press and a click are the same
event as far as anything downstream knows." Assistive technology presses the
element as a whole (the tab), not a sub-region of it the way a pointer click
can land inside `closeButton`'s frame; the close control is reached
separately, as its own republished accessibility child. (AppKit/UIKit.)
**Approved**: pending

**Decision**: The bar declares a reorder callback but never fires it; there is no drag-to-reorder or keyboard reordering interaction.
**Rationale**: Checked `TabBarView.swift`: `onReorder` is declared and `MultiTabbedViewController.swift` wires it to the delegate's `didReorderTab`, but the bar contains no drag-session or key handling that invokes it; the owner's `moveTab(id:to:on:)` reorders programmatically and notifies the delegate itself. Closing the gap would take a pointer drag (and keyboard equivalent) that computes a target index and calls `onReorder`.
**Approved**: pending

