
- **document-view-flipped**: The document view MUST use a top-down
  coordinate system, so hosted content top-anchors instead of using a
  bottom-up document origin (see Platform Notes for the source's exact
  mechanism).
- **content-top-leading-anchored**: The document view MUST be pinned to
  the top and leading edges of the scroll view's own visible content area
  (viewport).
- **content-width-matches-viewport**: Content installed via the
  set-content operation MUST have its width constrained equal to the
  scroll view's viewport width, so the content's own fitting width never
  drives the size of the panel or its containing window.
- **content-min-height-viewport**: Content installed via the set-content
  operation MUST have its height constrained to be greater than or equal
  to the scroll view's viewport height, so short content fills the
  viewport and taller content triggers vertical scrolling.
- **content-fills-document-edges**: Content installed via the set-content
  operation MUST be pinned to the top, leading, trailing, and bottom edges
  of the document view.
- **content-replacement-removes-previous**: The set-content operation
  MUST remove every existing child of the document view before installing
  the new content.
- **content-replacement-resets-scroll-position**: The set-content
  operation SHOULD reset the scroll position to the top when it replaces
  the hosted content. Source calls no explicit scroll API; the reset
  follows only as a side effect of removing the previous content's
  constraints (which collapses the document view to zero size until the
  new content is installed and re-constrained).
- **vertical-scroller-enabled**: The scroll view MUST enable a vertical
  scroll indicator.
- **horizontal-scroller-enabled**: The scroll view MAY enable a horizontal
  scroll indicator. Source enables it unconditionally at construction, but
  content installed via the set-content operation always matches the
  viewport width (see **content-width-matches-viewport**), so this
  indicator can never actually be triggered through the public API; ports
  need not mirror it.
- **scrollers-autohide**: The scroll view MUST autohide its scroll
  indicators.
- **background-transparent**: The scroll view MUST NOT draw its own
  background.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **programmatic-instantiation-only**: The component MUST NOT support
  construction through a deserializing/decoding-based construction path;
  any such call MUST be rejected (compile-time on platforms with static
  availability annotations, a runtime trap otherwise — see Platform Notes
  for the source's exact mechanism).

