
- **React / Web (TypeScript, source):** `packages/web/packages/crud/src/CrudTable.tsx`,
  exported from `@agentic-toolkit/crud`. Built from the shared `Button`, `Spinner`, and
  the package-local `ErrorText`; typography from `@agenticdevelopertoolkit/ui/lib/typography`
  (`fieldCaptionClass`). Note it lives in `@agentic-toolkit/crud`, not
  `@agenticdevelopertoolkit/ui`. Metadata comes from `src/generated/table-metadata.ts`,
  emitted by `packages/web/packages/adh-api-types/tools/gen_table_metadata.py` from the
  backend OpenAPI spec; `rows`/`loading`/`error` are typically supplied by
  `useCrudResource(meta)`. Demo: `ui-showcase` Topic `crud-table` (feeds a static `meta` +
  local `rows`). **Responsive:** the table is wrapped in `overflow-x-auto`, so it scrolls
  horizontally rather than overflowing the page on narrow viewports; verify at
  375 / 768 / 1440 via Playwright.
- **SwiftUI**: No native implementation exists (this is a web-sourced component). The
  equivalent would use a `Table` (macOS 13+ / iOS 16+) or a `List` of custom rows, one
  `TableColumn` (or `HStack` cell) per entry from `displayColumns`, a header
  `Button("New")`, per-row `Button("Edit")` / `Button("Delete")`, a `ProgressView` for
  the loading state, and a `ContentUnavailableView` for the empty state.
- **Compose**: No native implementation exists. The equivalent would use a `LazyColumn`
  with a header `Row` of column names and one data `Row` per record (each cell a
  `Text`), a `TextButton`/`IconButton` pair per row for Edit/Delete, a
  `CircularProgressIndicator` for the loading state, and a centered `Text` for the empty
  state.
- **AppKit / UIKit**: No native implementation exists. On AppKit the equivalent is an
  `NSTableView` with one `NSTableColumn` per entry from `displayColumns`, an
  `NSProgressIndicator` for the loading state, and a custom cell view whose trailing
  `NSButton`s call the Edit/Delete callbacks. UIKit has no direct multi-column table
  control, so the closest equivalent is a `UICollectionView` with a compositional
  layout (or a `UITableView` cell that stacks the scalar columns as labels) plus
  trailing swipe actions or accessory buttons for Edit/Delete.
- **WinUI 3**: No native implementation exists. The equivalent uses the Community
  Toolkit `DataGrid` (or a `ListView` with a `GridView`-style `ItemTemplate`), one
  column/cell per entry from `displayColumns`, a `ProgressRing` for the loading state,
  and per-row `Button`s in the row template for Edit/Delete.

