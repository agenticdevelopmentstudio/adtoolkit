
- **SwiftUI**: The source is pure AppKit (`NSView`/`NSTableView`), not
  SwiftUI. A SwiftUI counterpart would use `Table` (or `List` for a
  single-column case) driven by an `ObservableObject` wrapping the same
  `LogProvider` contract, one `TableColumn` per `LogColumn`, a tap gesture
  or context menu in place of `onClick`/`onDoubleClick`, and a
  `ScrollViewReader` with `scrollTo(id:anchor:.bottom)` in place of the
  scroll-to-end operation and `followTail`.
- **Compose**: Start from a `LazyColumn` (or a row of independently-scrolled
  `LazyColumn`s for true per-column widths) backed by a `StateFlow<List
  <LogLine>>` equivalent to `provider.lines`; per-column click hooks map to
  `Modifier.pointerInput` with `detectTapGestures(onTap, onDoubleTap)`; tail
  follow maps to `LazyListState.animateScrollToItem` on the last index,
  gated the same way — only when already near the bottom, or unconditionally
  on a full replace.
- **React/Web**: Use a virtualized table/grid fed the same column and line
  shape; per-column click handlers become `onClick`/`onDoubleClick` on each
  cell; tail follow is the common scrollback pattern — check whether the
  scroll container is within a small threshold of its bottom before an
  append, then scroll it to the bottom after the DOM updates, mirroring this
  component's pre-reload scroll check.
- **AppKit / UIKit**: This is the source platform (AppKit, macOS).
  `NSTableView`'s system-default `intercellSpacing` applies unmodified, and
  the table's row height comes from AppKit's system default for
  `rowSizeStyle: .default`. VoiceOver sees AppKit's built-in table
  accessibility hierarchy (table, then row, then cell) unmodified, since
  the component adds no custom `NSAccessibility` conformance or role
  override. The component, `LogProvider`, and `LogProviderDelegate` are all
  `@MainActor`-isolated, so every provider mutation and view update is
  serialized onto the main actor via Swift's actor isolation. The reference
  implementation also marks its `NSCoder`-based initializer (`init(coder:)`)
  unavailable at compile time and calls `fatalError` if it is ever invoked
  at runtime — a Cocoa/Interface-Builder construction rule with no
  counterpart on platforms without an NSCoder-based storyboard/XIB system: a
  call to construct the view that way fails to compile, or hits that
  `fatalError` at runtime if the unavailability check is somehow bypassed.
  A UIKit counterpart has no first-class multi-column table equivalent to
  `NSTableView`; it would use a `UITableView`/`UICollectionView` with a
  compositional, multi-column cell layout, a diffable data source driven by
  the same `LogProvider` contract, a tap and a long-press or double-tap
  gesture recognizer in place of the table's click and double-click
  actions, and a scroll-to-row operation in place of the scroll-to-visible
  call.
- **WinUI 3**: Model the table as a `DataGrid` (from the Windows Community
  Toolkit's WinUI controls), the closest match to a multi-column,
  user-resizable, per-cell-styled `NSTableView`; a plain `ListView` with a
  `Grid`-based row template is the alternative if avoiding that dependency.
  Map each `LogColumn` to a `DataGridTextColumn`/`DataGridTemplateColumn`
  with its `Width`, `MinWidth`, and `MaxWidth` bound from the column model;
  bind `ItemsSource` to an observable collection standing in for
  `provider.lines`; wire a tapped and a double-tapped handler on each cell
  to the same per-column `onClick`/`onDoubleClick` hooks; drive the selected
  row's highlight from a style targeting the row's background in its
  selected visual state, using the app's selection brush — WinUI's
  selection highlight is typically full-bleed rectangular, not the 4pt
  rounded, inset rectangle this AppKit view draws, which is worth calling
  out to implementers as an intentional visual difference rather than a
  bug; and implement tail follow by checking the scroll viewer's vertical
  offset against its scrollable height, using the same 2-point tolerance
  this file uses, before appending, then scrolling to the last item after
  the collection updates.

