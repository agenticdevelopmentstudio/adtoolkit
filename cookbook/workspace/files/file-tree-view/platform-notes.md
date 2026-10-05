
- **SwiftUI**: The source is pure AppKit (`NSViewController`/`NSOutlineView`),
  deliberately, not SwiftUI — the file's own header comment states that a
  SwiftUI `List` row's tap gesture does not fire reliably when attached to
  arbitrary row content, and that a directory's row, being a disclosure-group
  label, is not something a `List` will select at all; `NSOutlineView`
  selects on mouse-down for every row it draws, which this component relies
  on directly. A SwiftUI port would need `OutlineGroup` or a hand-rolled
  recursive `DisclosureGroup`/`List` combination verified specifically for
  whole-row tap and directory-row selection before adopting it, not a
  drop-in `List(rootNode, children: \.children)`.
- **Compose**: Flatten the currently-visible nodes (respecting each
  directory's expanded/collapsed state) into a single list driven by a
  `LazyColumn`, the way a Compose file-tree is conventionally built; back
  expansion/selection with `remember`/`mutableStateOf` or a `ViewModel`
  exposing `StateFlow`s equivalent to `FileBrowserSelection`/
  `FileBrowserRestorationState`, and trigger a lazy child load from the same
  "row entered the visible window and is a directory with no children yet"
  condition this file expresses as `outlineViewItemWillExpand`.
- **React/Web**: Model the tree as a virtualized list or a headless tree
  library (row-per-visible-node, like the Compose approach) rather than
  nested `<ul>`/`<li>` DOM for every directory, to avoid the DOM cost of a
  large monorepo tree; a row's whole clickable area maps to a single
  `onClick` handler rather than a nested interactive control, mirroring why
  this file avoids a component-per-row tap gesture.
- **AppKit / UIKit**: This is the source platform. The component configures a
  single-column `NSOutlineView` (wrapped as `ThemedOutlineView`) with
  `rowHeight = 22`, `indentationPerLevel = 14`, `style = .inset`, a hidden
  header (`headerView = nil`), a non-resizing outline column
  (`autoresizesOutlineColumn = false`), single selection only
  (`allowsMultipleSelection = false`), empty selection permitted
  (`allowsEmptySelection = true`), and an auto-hiding vertical scroller
  (`hasVerticalScroller = true`, `autohidesScrollers = true`), driving it as
  both `NSOutlineViewDataSource` and `NSOutlineViewDelegate`. Row content is a
  `FileTreeRowView` built from `ThemedLabel`s inside a horizontal
  `NSStackView`; the highlighted-row look comes from `ThemedTableRowView`.
  `init(coder:)` is marked unavailable at compile time and calls
  `fatalError` if invoked at runtime, since this controller is always
  constructed programmatically, never from a storyboard or archive. The
  neutral operations named throughout this recipe map onto concrete methods:
  the lazy children-load operation is `loadChildrenIfNeeded()`, the
  children-watch operation is `watchChildren(of:)`, the subtree-reload
  operation is `reloadItem(_:reloadChildren:)`, the open-if-file operation is
  `openIfFile(_:)`, the reveal and clear-reveal operations are `reveal(_:)`
  and `revealNothing()`, the test-only collapse-all operation is
  `collapseAllForTesting()`, and the disclosure-restore operation is
  `restoreDisclosure()`; expansion/collapse persistence calls
  `setExpanded(_:path:)` and selection persistence calls
  `setSelectedPath(_:)` on the restoration object. The context menu is built
  for `outline.clickedRow`, not the current selection. "Reveal in Finder"
  calls `NSWorkspace.shared.activateFileViewerSelecting(_:)`. A document
  event's URI is parsed with `URL(string:)`; a `nil` result is the
  unparseable case that is silently ignored. Icons are SF Symbols: package
  rows use `shippingbox.fill`; directories use `brain` for `.claude`,
  `arrow.triangle.branch` for `.git`, `folder.fill.badge.gearshape` for
  `Sources`/`Source`/`src`, `folder.fill.badge.questionmark` for
  `Tests`/`test`/`tests`, `folder.badge.gearshape` for any other
  dot-prefixed name, and `folder.fill` otherwise; files fall back to `doc`
  when no extension mapping applies. Git-status colors are fixed system
  colors rather than theme roles — for example `NSColor.systemOrange` for
  modified and `NSColor.systemRed` for deleted — read through
  `GitFileStatus.nsColor`. This controller, `FileTreeManager`,
  `FileBrowserSelection`, `FileBrowserRestorationState`, and
  `TextDocumentStore` are all `@MainActor`-isolated, and every Combine
  subscription it installs additionally hops `.receive(on: RunLoop.main)`;
  `loadChildrenIfNeeded()` itself reads the filesystem on a background queue
  but publishes the result back via `DispatchQueue.main.async`. Cross-pane
  feedback loops are broken by two independent guard flags,
  `isSyncingSelection` and `isSyncingExpansion`, which respectively suppress
  `outlineViewSelectionDidChange` and
  `outlineViewItemDidExpand`/`outlineViewItemDidCollapse` while a
  model-driven change is being applied. The ten localized strings are
  assigned directly as `String` literals to AppKit properties
  (`NSTextField`/`ThemedLabel` string values, `NSMenuItem.title`,
  `accessibilityDescription:`) rather than through any localization key or
  `NSLocalizedString` call; because this is an AppKit file, none of them gets
  SwiftUI's automatic `LocalizedStringKey` treatment. No animation API
  (`NSAnimationContext` or otherwise) is used, consistent with Reduce Motion
  being not applicable. The outline inherits `NSOutlineView`'s default
  keyboard and type-ahead handling unmodified. `NSOutlineView` itself has no
  direct iOS counterpart (`UIOutlineView` does not exist), but a
  `UICollectionView` configured with `UICollectionLayoutListConfiguration`
  and driven by an `NSDiffableDataSourceSectionSnapshot` has supported a
  native, hierarchical, disclosure-triangle outline since iOS 14 — that
  combination, not a manually flattened/indented `UITableView`, is the
  platform-idiomatic substitute.
- **WinUI 3**: Model the
  tree as a `TreeView` bound to a hierarchical `ItemsSource` mirroring
  `FileTreeManager`/`FileTreeNode` (one top-level `TreeViewNode` per root,
  matching `top-level-rows-are-managers`); use `TreeViewNode.HasUnrealizedChildren`
  plus the `Expanding` event to drive the same lazy-load-on-first-expand
  behavior as `expand-loads-children-lazily`, and the `Collapsed`/`Expanded`
  events to persist disclosure the way `expand-persists-to-restoration`/
  `collapse-persists-to-restoration` do. Drive `TreeView.SelectionChanged`
  into the same selection/target-root logic as
  `select-node-sets-node-and-target-root`, and use `TreeView.ItemInvoked`
  (or a double-tap gesture) for `double-click-opens-otherwise`. Build the
  context menu from `TreeViewItem.ContextFlyout` populated with
  `MenuFlyoutItem`s in the same Open/Open-in-New-Tab/Open-to-the-Side,
  separator, Reveal, Copy-Path order as `context-menu-item-order`, keyed off
  the flyout's own target node rather than the current selection — the WinUI
  analog of `context-menu-uses-clicked-row`. Represent the root-header
  emphasis (`target-root-header-emphasis`) as a `FontWeight`/`Foreground`
  binding on each root `TreeViewNode`'s content, driven by whichever root is
  the current target. Render the git-status badge as a `TextBlock` whose text
  and `Foreground` both bind to the node's status through a value converter
  mirroring `GitFileStatus.nsColor`'s fixed enum-to-color mapping, and the
  unsaved-changes marker as a small `Ellipse`/`FontIcon` whose `Visibility`
  binds to the same dirty flag, always present in the item template and
  toggled by binding rather than added/removed — the WinUI analog of
  `dirty-marker-always-built`.

