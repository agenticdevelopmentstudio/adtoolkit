
- **Corner radius**: Not applicable — the source never sets a corner
  radius; the component is only made layer-backed (see Platform Notes) so
  a background color can be painted.
- **Padding**: The internal stack is inset the standard panel-inset value
  (20pt) from the panel's top, leading, and trailing edges (equality
  constraints) and at most 20pt from the bottom edge (an inequality — see
  **bottom-inset-inequality**). Between arranged children, the default gap
  is the standard group-spacing value (20pt); the gap immediately above a
  heading added by the add-heading operation is widened to 1.5x that value
  (30pt) whenever a prior arranged child already exists.
- **Font**: Not applicable — the component renders no text of its own.
  Group captions and heading text belong to the Group View and Panel
  Heading View recipes, each of which documents its own typography.
- **Background**: The theme's window-background role, matching the
  source's own comment that this is "the same ground as the sidebar and
  the window."
- **Foreground/Text**: Not applicable — the component draws no text or
  icon of its own.
- **Border**: None — no border is drawn or configured anywhere in the
  source.
- **Shadow**: None — no shadow is drawn or configured anywhere in the
  source.
- **Min/Max size**: None declared by the component itself. Its width is
  whatever its superview gives it (no self-width constraint is set here,
  unlike the Group View's own width-matching behavior); its height is
  bounded below by the internal stack's accumulated content plus the 20pt
  top inset, but — per **bottom-inset-inequality** — the view MAY be
  taller than that, leaving unused space below the last arranged child.

