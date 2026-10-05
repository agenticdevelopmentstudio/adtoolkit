
**Decision**: A tab's `groupID` defaults to its own `id` rather than requiring
every caller to supply one.
**Rationale**: Per `Tab.init`'s doc comment, this "makes a tab its own group of
one — the behaviour every host had before groups existed," so a caller with
only one edge needs no change to keep working. (AppKit/UIKit.)
**Approved**: pending

**Decision**: `activateFallbackTab()` looks for a same-group sibling on any
enabled edge before falling back to the first tab of the first enabled edge.
**Rationale**: Per the method's doc comment, turning an edge off "is a decision
about where tabs are drawn," and jumping instead to an unrelated tab on the
first enabled edge "dropped [the user] onto an unrelated checkout" — the
group-first fallback keeps the user's actual selection stable across edge
visibility changes. (AppKit/UIKit.)
**Approved**: pending

**Decision**: `contentInsets` is applied by `MultiTabbedViewController` around
the mounted content, rather than left to the content itself.
**Rationale**: Per the property's doc comment, the tab bars "have to stay flush
against the window," so the gap belongs between the bars and what they
frame, and "this controller is the only thing that owns both." (AppKit/UIKit.)
**Approved**: pending

**Decision**: `activeTabDidChange` fires on every activation — including
transitions to `nil` — while `didSelectTab` fires only for a user-driven
pick (a click, or the neighbor/fallback a close hands the user).
**Rationale**: Per the delegate's doc comments, a host that only needs "which
pane is in front now" should not have to separately filter fallback and
clearing transitions out of genuine user picks; the two callbacks
deliberately separate "what changed" from "the user chose this." (AppKit/UIKit.)
**Approved**: pending

**Decision**: `TabBarView.rebuildButtons()`'s reconciliation tears down a hosted
controller only if that controller's view still sits in *this* bar's own
wrapper.
**Rationale**: Per the method's doc comment, a cross-edge move reparents the
controller's view onto the new bar's wrapper before the old bar notices the
id is gone from its own items; tearing it down there too "would rip the
view out of the new bar's display." (AppKit/UIKit.)
**Approved**: pending

**Decision**: (documented quirk, not a deliberate design choice) the
front-to-back z-reordering and `stackDepth` reporting in
`TabBarView.applyStackOrder()` only cover `.viewController` items (via
`hostViews`/`hostedControllers`). A `.title` `TabButton` on a vertical
(`.left`/`.right`) edge still receives the same `-16pt` overlapping
`stack.spacing` as hosted items, but is never reordered by distance from the
selected item — its z-order, and therefore which overlapping title tab
draws and hit-tests on top, is left at whatever order
`NSStackView.addArrangedSubview` produced (list order), regardless of which
tab is selected.
**Rationale**: `hostViews`/`hostedControllers` are populated only for
`.viewController` items, so `applyStackOrder()`'s reordering loops have
nothing to reorder for title tabs; nothing in source suggests this was a
deliberate choice for the title-tab case rather than an oversight. Recorded
here, per source fidelity, rather than smoothed over. (AppKit/UIKit.)
**Approved**: pending

