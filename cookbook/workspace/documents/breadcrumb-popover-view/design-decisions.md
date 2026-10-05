
- **Decision**: Give the popover's root view an explicit pixel frame
  (`NSRect(origin: .zero, size: Self.contentSize)`) in `loadView()`,
  alongside setting `preferredContentSize` in `init`.
  **Rationale**: Per the `loadView` source comment, `NSPopover` sizes an
  Auto-Layout content view to that view's fitting size and ignores its own
  `contentSize`; with no subview here having an intrinsic width, an unsized
  root would collapse to a 16×46pt sliver. The frame gives the root view an
  explicit width and height (since `translatesAutoresizingMaskIntoConstraints`
  stays `true` on it) for the constrained subviews to hang from, matching
  what `preferredContentSize` tells the popover separately.
  **Approved**: pending
- **Decision**: Reuse `PickerKeyboardController` for keyboard wiring and
  `ProjectFilter.ranges(of:in:)` for match highlighting instead of
  implementing either locally.
  **Rationale**: Per the type's doc comment, these are "the same two pieces
  the provider and model pickers already share" — reusing them keeps
  keyboard behavior and match highlighting consistent across every
  filterable picker in the app instead of a fourth, divergent implementation.
  **Approved**: pending
- **Decision**: Guard `chooseAction()` so choosing a directory row is a
  no-op instead of navigating into the subdirectory.
  **Rationale**: Per the type's doc comment, "Choosing a directory row does
  nothing; only files can be opened from here" — this popover is scoped to
  opening a file at the crumb's own directory level, not to browsing further
  down the tree.
  **Approved**: pending
- **Decision**: Unconditionally reselect row 0 in `applyFilter()` after
  every filter change, rather than preserving the previous selection or
  re-selecting the closest surviving match.
  **Rationale**: `applyFilter()` calls `selectRow(0)` on every invocation
  with no branch to preserve prior selection identity; this keeps the
  type-to-narrow-then-Return flow always landing on the top result without
  added logic to track selection identity across filter changes.
  **Approved**: pending

