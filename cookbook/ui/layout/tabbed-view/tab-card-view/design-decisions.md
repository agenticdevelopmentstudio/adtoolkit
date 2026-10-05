
- **Decision**: (AppKit) `init?(coder:)` is `@available(*, unavailable)` and its
  body returns `nil` rather than calling `fatalError()`.
  **Rationale**: The `unavailable` attribute already makes this initializer
  uncallable from Swift source, so the body is unreachable in practice;
  returning `nil` here (and in the file-private `TabCardBackgroundView`'s own
  `init?(coder:)`) is what this file does, rather than the `fatalError()`
  pattern used by some other AppKit types in the codebase — noted here per
  source fidelity rather than smoothed over.
  **Approved**: pending
- **Decision**: `stackDepth` accepts any `Int` with no clamp, and
  `recession(atDepth:)` treats any non-positive depth as zero recession while
  `isFrontCard` still requires `stackDepth == 0` exactly.
  **Rationale**: `TabBarStackedItem.stackDepth`'s own doc comment defines depth as
  "0 for the selected item itself, 1 for either neighbour, and on outward" —
  non-negative by contract — and the one caller in this codebase
  (`TabPaneViewController.applyDepth()`) always passes `max(1, stackDepth)` or
  `0`, so a negative depth never currently reaches this view. Nothing in
  `TabPaneView.swift` itself enforces that contract, so the combination is
  recorded here per source fidelity rather than assumed away.
  **Approved**: pending
- **Decision**: `recession(atDepth:)` grows with depth only on a vertical
  (`.left`/`.right`) edge; a horizontal (`.top`/`.bottom`) edge gets the same
  flat `4pt` inset at every depth greater than zero.
  **Rationale**: Per `Edge.isVertical`'s and `TabPaneView.recession`'s own doc
  comments, only a vertical bar lays its cards in a column with room to
  recede down; a horizontal bar's cards sit side by side along their long
  axis with no depth to show, so there is nothing for a second or third step
  to add.
  **Approved**: pending
- **Decision**: (AppKit) The card's own view is left unpinned on both axes — no
  self-constraint on width or height.
  **Rationale**: Per `setUp()`'s inline comment, the cross axis is the hosting
  bar's own required-priority constraint (`TabBarView.rebuildButtons()`) and
  the length axis is AppKit's own priority-501
  `NSViewController.preferredContentSize` constraint, driven by
  `contentSize`; a required self-pin here would restate one of those two
  numbers at required priority and risk an unsatisfiable conflict with
  whichever one wins.
  **Approved**: pending
- **Decision**: (AppKit) `contentSize` measures `content.fittingSize`, not the
  card's own `fittingSize`.
  **Rationale**: Per the property's doc comment, `TabPaneViewController` installs
  AppKit's priority-501 `preferredContentSize` constraints onto the card
  itself, and the labels resist compression at only `.defaultLow` — so asking
  the card for its own `fittingSize` after a first measurement would return
  that first answer again, and a card whose text grows on a later `reload()`
  would never widen. The stack (`content`) carries none of those constraints,
  so it is measured instead.
  **Approved**: pending

