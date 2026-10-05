
- **Corner radius**: Not applicable — the split and its items draw no custom
  layer or corner radius anywhere in this component's own drawing.
- **Padding**: Not set by this component directly. A separate, app-wide
  content-inset setting (four independently configurable edge values, each
  `0` by default) is applied around the pane area by the window/container
  that hosts a root split node; this component itself sets no content insets
  on its own view.
- **Font**: Not applicable — this component draws no text of its own; any
  text belongs to the panes it hosts.
- **Background**: A divider wider than 1pt is filled with the theme's
  pane-backdrop color, so a wide gutter reads as the same backdrop plane the
  frame spacing shows, not a colored bar; a divider at or under 1pt falls
  back to the split view's own default drawing.
- **Foreground/Text**: Not applicable — no text is drawn by this component.
- **Border**: Not applicable — no border is configured on the split view or
  its items anywhere in source.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: A pane's minimum thickness comes from its registered view
  descriptor (`120pt` by default); a nested split's minimum is the sum of its
  children's minimums along the split's own axis, or the max of them across
  it. A divider's thickness is the between-columns spacing (vertical split)
  or the between-rows spacing (horizontal split) — both `1pt` by default —
  and its draggable hit area is widened to at least the minimum divider grab
  width (`6pt`) without changing the drawn gutter width. A minimized pane is
  pinned to a fixed thickness (its minimum thickness equal to its maximum
  thickness) computed by the pane itself.

