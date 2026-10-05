
- **SwiftUI**: Use a `List(filteredEntries, selection: $selectedID)` inside a
  `.popover`/sheet, with a `.searchable(text: $filterText)` modifier feeding
  the same substring-match predicate as `applyFilter`. Bind arrow-key,
  Return, and Escape handling via `.onKeyPress(_:)` in place of
  `PickerKeyboardController`'s command-selector routing, and highlight
  matched-range substrings by building an `AttributedString` per row with
  `.bold()` applied to the matched runs, mirroring `attributedTitle(for:)`.
  Give the list a fixed `.frame(width: 280, height: 320)` (matching
  fixed-content-size) in place of `preferredContentSize`. A directory row's
  tap/selection action should be a no-op, mirroring `guard !node.isDirectory`.
- **Compose**: Host in a `Popup` or `DropdownMenu` sized to a fixed
  280×320dp `Box` (matching fixed-content-size). Compose's `LazyColumn` has
  no built-in keyboard-driven
  single selection the way `NSTableView` plus `PickerKeyboardController`
  provides, so intercept Up/Down/Enter/Escape with
  `Modifier.onPreviewKeyEvent` on the filter `OutlinedTextField`, moving a
  `selectedIndex` state and calling `LazyListState.animateScrollToItem` — the
  Compose analog of `scrollRowToVisible`. Render matched substrings with
  `buildAnnotatedString` and `SpanStyle(fontWeight = FontWeight.Bold)` over
  the matched ranges. A directory row's `onClick` should be a no-op,
  mirroring `guard !node.isDirectory`.
- **React/Web**: A fixed 280×320px container (matching fixed-content-size)
  with an `<input type="search">`
  for the filter (its `onChange` re-filters immediately, mirroring
  `sendsSearchStringImmediately`/`controlTextDidChange`) above a
  `<ul role="listbox">` of `<li role="option">` rows. Implement Up/Down/
  Enter/Escape in the input's `onKeyDown` handler, updating a `selectedIndex`
  state and calling `element.scrollIntoView({ block: "nearest" })` on the
  newly selected row, mirroring `scrollRowToVisible`. Render matched
  substrings by wrapping the matched ranges in a bold `<strong>`/span,
  mirroring `attributedTitle(for:)`. A directory row should ignore both click
  and Enter-to-choose, mirroring `guard !node.isDirectory`.
- **AppKit/UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/DocumentPane/BreadcrumbPopoverViewController.swift`.
  A `@MainActor`, `final` `NSViewController` presented as the content view
  controller of an `NSPopover` opened by a `BreadcrumbView` crumb. It loads
  the directory's immediate children via `FileTreeNode.loadChildren(for:)`
  synchronously in `init`, and row names come from `FileTreeNode.name`. It
  builds its view by hand in `loadView()` — an `NSSearchField` above an
  `NSTableView` wrapped in an `NSScrollView` (with `scrollView.borderType =
  .noBorder` and no border configured on the search field or table view),
  laid out with Auto Layout constraints against a root `NSView` given an
  explicit 280×320 frame (`Self.contentSize`, also set on
  `preferredContentSize` as `NSSize(width: 280, height: 320)`; see the
  loadView-frame Design Decision) — rather than loading a nib or using
  SwiftUI. The table's single column (`NSTableColumn`, identifier
  `"breadcrumb.entry"`) has a fixed width of 248pt (`column.width`) and
  `headerView == nil`; `tableView.allowsEmptySelection` and
  `allowsMultipleSelection` are both `false`, and `selectRow`/`moveSelection`
  are the concrete methods behind clamp-selection-to-list-bounds and
  relative-selection-movement, with `scrollRowToVisible` behind
  scroll-selection-into-view. The row label is an
  `NSTextField(labelWithString:)` using `NSFont.systemFont(ofSize:
  NSFont.smallSystemFontSize)` for unmatched characters and
  `NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)` for matched
  ones, with `lineBreakMode == .byTruncatingMiddle`; no custom `NSColor` is
  set anywhere, so text color comes from the label's AppKit default.
  Filtering (`applyFilter`), keyboard navigation (`PickerKeyboardController`,
  wired in `viewDidAppear`), and match highlighting
  (`ProjectFilter.ranges(of:in:)`, applied in `attributedTitle(for:)`) are
  shared collaborators reused from the app's other filterable pickers, not
  reimplemented locally. Keyboard routing (arrow-keys-move-selection,
  return-key-chooses-selection, escape-key-cancels) is wired in
  `viewDidAppear` by assigning `keyboard.onMoveSelection`,
  `keyboard.onChoose`, and `keyboard.onCancel` closures and calling
  `keyboard.startEscapeMonitor(for: view.window)`; the monitor is stopped in
  `viewWillDisappear`. Because `NSSearchField` normally consumes arrow keys,
  Return, and Escape as ordinary text-editing commands, the
  `NSSearchFieldDelegate` method `control(_:textView:doCommandBy:)`
  intercepts those command selectors first and forwards them to
  `keyboard.handle(_:)`, returning its `Bool` result so AppKit knows the key
  was handled; this delegate method is also what gives the search field
  first-responder focus in `viewDidAppear` (focus-filter-field-on-appear).
  Row views (reuse-row-views) come from
  `tableView.makeView(withIdentifier:owner:) as? NSTableCellView`, falling
  back to constructing a new `NSTableCellView` only when none is available
  for reuse. `chooseAction()` guards on `!node.isDirectory` for the
  directory-is-inert behavior. Accessibility identifiers
  (`"breadcrumb.popover.filter"`, `"breadcrumb.popover.table"`) are set via
  `accessibilityID(_:)`; no explicit `setAccessibilityRole`/
  `setAccessibilityElement`/`setAccessibilityLabel` call is made anywhere,
  and no `NSAccessibility.post(element:notification:)` call announces a
  filtered-result-count change. No `NSAnimationContext` call wraps any state
  change; every reload goes through synchronous `reloadData()`.
  `init(coder:)` is overridden to call `fatalError` unconditionally
  (no-decoded-initialization). There is no UIKit code path in source; a
  UIKit port would replace `NSSearchField`/`NSTableView` with
  `UISearchBar`/`UITableView`, present the whole thing in a
  `UIPopoverPresentationController` (iPad) or a sheet (iPhone) instead of
  `NSPopover`, would need to grow the 20pt AppKit row height to at least a
  44pt touch target, and would need `UIKeyCommand`-based hardware-keyboard
  handling to reach parity with `PickerKeyboardController`'s arrow-key/
  Return/Escape routing, since UIKit has no built-in equivalent.
- **WinUI 3** (the reason this recipe exists): Build the popover content as
  a `TextBox` with a `TextChanged` handler (not an `AutoSuggestBox`: its
  built-in suggestion flyout would open its own popup list directly under
  the box, clashing with the separate `ListView` this recipe already needs
  below it) stacked above that `ListView`, bound to the filtered collection,
  both hosted inside a `Flyout` (not a `MenuFlyout`, since arbitrary content —
  a search box plus a list — is needed, mirroring the AppKit choice of
  `NSPopover` over a plain menu) anchored to the breadcrumb crumb's button,
  sized to a fixed 280×320 epx `Grid` (matching fixed-content-size) in place
  of `preferredContentSize`. Update the `ListView`'s bound collection on
  every `TextBox.TextChanged` event, mirroring `applyFilter`'s
  `query.isEmpty ? entries : entries.filter { ... }` substring match, and
  reselect index 0 after every filter change, mirroring
  `reselect-first-row-after-filter`. Since WinUI has no `doCommandBy:`-style
  command-selector routing, intercept Up/Down/Enter/Escape in the
  `TextBox`'s `PreviewKeyDown` handler, moving
  `ListView.SelectedIndex` and calling `ListView.ScrollIntoView(item)` — the
  direct analog of `scrollRowToVisible` — for Up/Down, invoking the choose
  logic for Enter, and calling `Flyout.Hide()` for Escape, the analog of the
  cancel callback. Render each row as a `TextBlock` containing multiple `Run`
  elements with `FontWeight="Bold"` applied to the matched ranges from the
  same substring-match logic, mirroring `attributedTitle(for:)`, and set
  `TextTrimming="CharacterEllipsis"`; note that WinUI's built-in ellipsis
  trims from the end, so approximating AppKit's middle-truncation
  (`truncate-row-label-middle`) requires either manual string splitting
  around the matched range or accepting end-truncation as the closest native
  equivalent — call this out to implementors as a deliberate platform
  difference. A `ListViewItem` bound to a directory entry should be a no-op
  in the `ItemClick`/`SelectionChanged` handler, mirroring
  `guard !node.isDirectory`.

