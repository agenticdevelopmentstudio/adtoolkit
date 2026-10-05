
**Decision**: The detail-pane minimum-thickness floor floors the detail
pane's minimum thickness rather than a required-width constraint on the
detail content.
**Rationale**: This "lets the detail grow freely, unlike a required width
constraint on the content, which pins the window"; it is "the proper lever
for the window's minimum width (window min = sidebar thickness + this)."
**Approved**: pending

**Decision**: The content-sized-sidebar flag defaults to `false` for this
base component (the draggable, persisted band), even though nested splits
generally want `true`. (AppKit.)
**Rationale**: "The full-height *root* window sidebar keeps the draggable
behaviour (its outline's column-fill misbehaves under a fixed width).
Nested topic/detail splits opt in — they're the ones that visibly 'move
around' as you switch between them."
**Approved**: pending

**Decision**: Search-enabled and sort-by-title both default to `false`
and are switched on only for the window's root split.
**Rationale**: A nested split's sidebar is "a table of contents for one
panel" written in an intentional order, while the root window's list is
"a set of unrelated destinations" a reader can only find by name or by
search; a second search field inside an outer split's already-filtered
results "is a maze."
**Approved**: pending

**Decision**: Moving the selection by a step (arrow-key stepping) leaves
the search field's text and query untouched, unlike selecting a panel or
navigating back/forward, which all clear it.
**Rationale**: "The query is the very thing the reader is steering by
when they press Down, so clearing it would throw away the list they are
moving through and jump the highlight somewhere else."
**Approved**: pending

**Decision**: This component intercepts the search field's Down/Up
key commands through the platform's own field-editing delegation, rather
than through a lower-level key-event override, returning "not handled"
for every other command. (AppKit.)
**Rationale**: This is answered "rather than in a `keyDown` override
because AppKit has already turned the key into the reader's intent by this
point — and returning false for every other command leaves the rest of
text editing exactly as it was."
**Approved**: pending

**Decision**: The current-panel-title and effective-help queries both
recurse into a selected panel that is itself a settings split view,
reporting that inner split's own title/help rather than this instance's.
**Rationale**: "A split whose selected panel is itself a split answers
with the topic selected *inside* it: that is the panel the reader is
looking at," and naming the outer container instead "left the toolbar
stuck on the container's name while the reader moved down its list."
**Approved**: pending

**Decision**: The sidebar-unification step leaves the nested-detail floor
unchanged (rather than resetting it toward `0`) whenever the current
panel set has fewer than two nested settings-split-view panels.
**Rationale**: Not stated in source. The method's early exit returns
before recomputing the floor, so a detail-pane floor raised while two or
more nested splits were present can outlive their removal until a later
state again has two or more. Documented here as observed behavior (see
Edge Cases and split-view-controller-054), not as a deliberate design
tradeoff.
**Approved**: pending

