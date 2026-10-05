
- **Decision**: Constrain the internal stack's bottom edge with an
  inequality rather than an equality constraint, unlike the
  top/leading/trailing edges.
  **Rationale**: Not explained in source comments beyond the code itself.
  An inequality lets the stack's own computed height determine the
  panel's occupied region without forcing the stack to stretch and fill a
  taller frame the panel happens to be given, the same "size to content,
  not to container" outcome the Group View's sibling recipe gets from
  having no height constraint of its own at all.
  **Approved**: pending
- **Decision**: (AppKit) The designated `init(frame:)` ignores the
  caller-supplied `frameRect` entirely and always forwards `.zero` to
  `super.init(frame:)`.
  **Rationale**: Not explained in source comments; the effect is that no
  caller can give the component a non-zero initial frame, even by
  bypassing the parameterless construction path. This is a known quirk
  rather than a deliberate API contract — kept as-is because it is what
  the source does (see the frame edge case above).
  **Approved**: pending
- **Decision**: (AppKit) Resolve the background color through a
  `ThemePaletteObserver(host: self)` rather than reading the unscoped,
  app-wide palette once at construction.
  **Rationale**: Per the source's own comment, this keeps the panel's
  ground the same as "the sidebar and the window," painted from the
  component's own resolved theme scope rather than a single global
  palette, and it stays live for the view's lifetime rather than being
  captured once.
  **Approved**: pending
- **Decision**: The add-heading operation widens the gap above a heading
  to 1.5x the group-spacing value only when a prior arranged child already
  exists, rather than always applying the wider spacing or applying it to
  the gap below the heading.
  **Rationale**: Per the source's own doc comment, "the gap above a
  heading is wider than the gap between two cards, because that gap is
  what says the heading belongs to what comes *after* it — at the stack's
  own spacing it reads as a caption trailing the card above." A first
  heading with nothing above it needs no such signal, so no adjustment is
  made.
  **Approved**: pending
- **Decision**: (AppKit) The deserializing-construction path traps via
  `fatalError`, and its current message text (`not overridden`) is left
  as-is rather than standardized to match the sibling Group
  View/Panel Heading View message (`init(coder:) has not been
  implemented`).
  **Rationale**: The message text is not part of the
  **rejects-deserializing-construction** requirement; the mismatch is a
  real, source-traceable inconsistency between siblings, not smoothed
  over in either direction.
  **Approved**: pending

