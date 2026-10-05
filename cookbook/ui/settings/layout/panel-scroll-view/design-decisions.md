
**Decision**: Pin installed content's width equal to the viewport's width,
and its height only greater-than-or-equal to the viewport's height, rather
than letting the content's own intrinsic size dictate the panel's size.
**Rationale**: Per the source's own doc comment, the owning split view
controller wraps every non-self-scrolling panel in a Panel Scroll View,
and master/detail pickers host their detail panes in one, specifically so
that rebuilt content can never tug a split view's divider; pinning width
and floor-ing height keeps the panel's own footprint stable regardless of
what content is installed.
**Approved**: pending

**Decision**: Enable both the vertical and horizontal scroll indicators,
even though content-width-matches-viewport pins installed content's width
exactly to the viewport width, which means content added through the
set-content operation alone can never actually trigger horizontal
scrolling.
**Rationale**: (AppKit) Source sets `hasHorizontalScroller = true`
unconditionally in `init`, before any content exists; it is not gated on
content width. Because the document view is private, callers have no path
to add subviews outside `setContent(_:)`, so the horizontal scroller is
incidental configuration rather than support for any caller-reachable
overflow case.
**Approved**: pending

**Decision**: (AppKit) Use a private `FlippedDocumentView` with
`isFlipped == true` rather than the platform's default (unflipped)
document view.
**Rationale**: Per the source's own doc comment, settings content reads
top-to-bottom, and an unflipped document view places its origin at the
bottom-left, which would anchor new content at the bottom of the
scrollable area instead of the top.
**Approved**: pending

**Decision**: (AppKit) Disable `init(coder:)` with
`@available(*, unavailable)` and a `fatalError`, leaving the parameterless
`init()` as the only usable initializer.
**Rationale**: The component has no archive-restorable state — it is
configured entirely by construction and then by a caller's set-content
call — so the decoding-based initializer that archive/nib loading would
otherwise use is intentionally disabled. Because the initializer is marked
unavailable, any call is rejected by the compiler rather than reaching the
`fatalError()` at runtime.
**Approved**: pending

