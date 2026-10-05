
- **Decision**: (AppKit) Cache `TopicListNode` instances in `rootNodesCache`
  across accesses, rebuilding them only inside `setSections(_:)`, instead
  of recomputing `rootNodes` fresh on every access.
  **Rationale**: Per the property's doc comment, `NSOutlineView` identifies
  items by reference; rebuilding on every access (the prior behavior) made
  `outlineView.row(forItem:)` always return -1, which silently broke
  `selectItem(withId:)`.
  **Approved**: pending
- **Decision**: Let `shouldSelectItem` and `TopicListItemLabel.accessibilityPerformPress()`
  gate selection only on node kind (`.item` vs. `.header`), never on
  `TopicListItem.isDisabled`.
  **Rationale**: Source draws no such distinction - a "coming soon" placeholder
  item stays reachable and selectable by mouse, keyboard, and assistive
  technology alike; only its rendered appearance is muted. A consumer that
  wants a disabled item to be truly inert must check `isDisabled` itself
  inside its `onSelect` handler.
  **Approved**: pending
- **Decision**: (AppKit) Track suppression of `onSelect` with an integer
  nesting counter (`selectionSuppressionDepth`), not a boolean flag.
  **Rationale**: Per the property's doc comment, a single suppression scope must
  absorb both the notification `reloadData()` posts when it drops the
  selection and the one the following re-selection posts - AppKit delivers
  both synchronously within the scope - so the counter, not a one-shot
  flag, is what keeps a single scope correct.
  **Approved**: pending
- **Decision**: (AppKit) Override `layout()` on `ColumnFillingOutlineView` to
  call `sizeLastColumnToFit()` after `super.layout()`, rather than setting
  the column's `width` directly.
  **Rationale**: Per the class's doc comment, setting `column.width` directly
  from `layout()` re-enters `NSTableView.tile`/`setFrameSize` and throws;
  `sizeLastColumnToFit()` after `super.layout()` is the safe primitive.
  **Approved**: pending
- **Decision**: (AppKit) Set `outlineView.style = .automatic` rather than the
  more visually apt `.sourceList`.
  **Rationale**: Per the source comment, `.sourceList` forces an internal
  `NSVisualEffectView` dark material regardless of `NSApp.appearance`;
  `.automatic` lets the outline's background follow this component's own
  theme instead.
  **Approved**: pending
- **Decision**: (AppKit) Pin `contentStack`'s top anchor to the root view's
  `safeAreaLayoutGuide.topAnchor` instead of its plain `topAnchor`.
  **Rationale**: Per the source comment, in a window whose content runs the
  full height (so the sidebar's fill reaches up behind the window buttons)
  the titlebar overlaps this view, and the list must begin below it;
  everywhere else that inset is zero and nothing moves.
  **Approved**: pending
- **Decision**: (AppKit) Put the accessibility identifier and `AXPress`
  handling on the item's `NSTextField` label (`TopicListItemLabel`), not
  on `NSTableCellView` or `NSTableRowView`.
  **Rationale**: Per the source comment, AppKit synthesizes a table's `AXRow`
  and `AXCell` elements itself; an identifier or action attached to
  `NSTableRowView`/`NSTableCellView` never reaches the accessibility tree,
  so the label is the row's one real element in it.
  **Approved**: pending
- **Decision**: Derive an item row's accessibility identifier from its `title`
  (slugified), not from its `id`.
  **Rationale**: Per the source comment, `id` is the caller's private key - in
  the settings window it is a panel's index in an array - so it names
  whichever row a given index currently holds and renames itself whenever a
  row is inserted above it. The title is what the row is called on screen,
  which is what someone driving the list actually knows about it.
  **Approved**: pending

