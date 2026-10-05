
- **card-surface**: Component MUST construct its card surface filled with
  the `.elevatedSurface` role, no stroke, and a corner radius of 10pt.
- **card-view-access**: Component MUST expose its card surface as a public,
  read-only property.
- **header-from-title**: Constructing the component from a title string
  MUST build a header view from that string and use it as the group's
  caption.
- **arbitrary-header-view**: Component MUST accept any view as the group's
  caption, not only its own default header view.
- **header-above-card**: Component MUST place the header view above the
  card, in that order, in a vertical, leading-aligned stack.
- **header-card-spacing**: Component MUST set the spacing between the
  header and the card to 6pt.
- **outer-stack-edge-pinning**: Component MUST make the header-and-card
  stack fill its own bounds edge-to-edge, with no additional inset.
- **header-width-match**: Component MUST constrain the header view's width
  to match the header-and-card stack's width.
- **card-width-match**: Component MUST constrain the card's width to match
  the header-and-card stack's width.
- **row-area-edge-pinning**: Component MUST make the row area fill the
  card's bounds edge-to-edge, with no additional inset.
- **row-stacking**: Component MUST lay out rows in a vertical, leading-
  aligned stack with `0` spacing between adjacent rows.
- **superview-width-match**: When the component is added to a parent, it
  MUST size itself to match that parent's width.
- **width-match-skip-without-superview**: The component MUST NOT attempt to
  match a parent's width when it has no parent to match yet.
- **row-append**: Adding a row to the group MUST wrap it as the card's next
  row and add it to the end of the card's visible row order, growing the
  card's row count by one.
- **default-row-style**: Adding a row with no style specified MUST default
  to the standard row style.
- **added-row-width-match**: Component MUST constrain each newly added
  row's width to match the row area's width.
- **self-hiding-content-wiring**: When a row's content can report when it
  hides itself, adding that row MUST subscribe to that report so that the
  content hiding re-syncs the row's own visibility and then recomputes
  every row's separators.
- **separator-recompute-on-add**: Adding a row MUST recompute every row's
  separator visibility immediately after the row is appended.
- **separator-visibility**: Component MUST show a divider above a row only
  when a strictly-earlier row in the card's row order is not hidden AND the
  current row's own style is the standard row style; a continuation-style
  row's divider MUST always be hidden.
- **first-row-headless**: The first row in the card's row order MUST NOT
  show a divider regardless of its style, because no earlier row exists for
  it to follow.
- **row-visibility-binding**: A row's own hidden state MUST always equal its
  wrapped content's hidden state.
- **row-visibility-at-construction**: A newly constructed row MUST already
  reflect its content's hidden state before construction returns.
- **separator-collapse**: When a row's separator visibility is turned off,
  its divider MUST become hidden and the space reserved for it MUST collapse
  to zero height.
- **separator-expansion**: When a row's separator visibility is turned on,
  its divider MUST become visible and the space reserved for it MUST expand
  to the standard 1pt divider thickness.
- **separator-write-idempotency**: Setting a row's separator visibility to
  its own current value MUST NOT change the divider's hidden state or the
  reserved space's height.
- **separator-inset**: A row's divider MUST be inset from the row's leading
  edge by 14pt and MUST reach flush to the row's trailing edge.
- **row-content-padding**: For a standard-style row, Component MUST inset
  the wrapped content's top edge below the divider band by 9pt, and inset
  the content's bottom edge from the row's own bottom edge by the same 9pt.
- **continuation-padding**: For a continuation-style row, Component MUST
  inset the wrapped content's top edge from the divider band by `0`, while
  still applying the 9pt bottom inset.
- **row-content-horizontal-inset**: Component MUST inset the wrapped
  content's leading and trailing edges from the row's own corresponding
  edges by 14pt on each side.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

