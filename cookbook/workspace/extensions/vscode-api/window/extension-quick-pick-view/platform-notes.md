
- **SwiftUI**: Compose a `List`/`ForEach` over the model's visible items
  with a `TextField` (or `.searchable`) driving the filter text, but plan
  explicitly for keyboard routing: SwiftUI's default `List` moves system
  focus into row items on arrow-key navigation, which would break the
  source's "search field never loses first responder" behavior
  (`search-field-focus`) unless arrow/return/escape are intercepted
  with `.onKeyPress` (or an `NSEvent` local monitor bridged in) at the
  text field itself, mirroring `PickerKeyboardController`. Represent
  `visibleIndices`/`highlightedIndex`/`checkedIndices` as `@Published`
  properties on an `ObservableObject` wrapping the same filtering rules as
  `ExtensionQuickPickModel`.
- **Compose**: Use a `LazyColumn` of filtered items with an
  `OutlinedTextField` for search, and register `Modifier.onKeyEvent` (or a
  hardware key listener) on the text field for Up/Down/Enter/Escape so
  Compose's own focus system does not move focus into row items — the
  same risk as SwiftUI's `List`. Track "highlighted" as separate state
  from Compose's own selection, and drive an optional leading `Checkbox`
  per row from a `Set<Int>` mirroring `checkedIndices`, rather than
  `LazyColumn`'s own multi-select gesture handling.
- **React/Web**: An `<input type="search">` feeding a filtered `<ul>`/`<div
  role="listbox">` list, with `onKeyDown` handling `ArrowUp`/`ArrowDown`/
  `Enter`/`Escape` while keeping DOM focus in the input and using
  `aria-activedescendant` to indicate the highlighted row — mirroring the
  source's `refusesFirstResponder` table plus focused search field, rather
  than moving DOM focus into list items. Render an optional leading
  `<input type="checkbox">` per row for multi-select, explicitly paired
  with a `<label>` (or `aria-labelledby`) referencing that row's title —
  closing the accessible-label gap flagged in Accessibility above rather
  than reproducing it.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/Features/Extensions/UI/ExtensionQuickPickViewController.swift`.
  A macOS-only (`import AppKit`) `NSViewController`, `@MainActor`,
  composing an `NSSearchField` and a `ThemedTableView` inside an
  `NSScrollView`, with `PickerKeyboardController` for keyboard routing and
  a private `NSEvent` local monitor for Escape. There is no UIKit code
  path in source; a UIKit port would replace the search field with
  `UISearchController`/`UISearchBar`, the table with `UITableView`, and
  would need its own keyboard-routing solution via `UIKeyCommand` in place
  of `doCommandBy:`, since UIKit has no equivalent hook.
  `ExtensionQuickPickViewController` is constructed via `init(model:)` with
  a required, non-optional `ExtensionQuickPickModel`, and does not support
  `init(coder:)`; invoking `init(coder:)` traps with a fatal error
  (**required-model-construction**). It sets `preferredContentSize` to
  560×400 points during `init`, before `loadView` runs
  (**fixed-content-size**). Filtering is driven by `controlTextDidChange`
  on the search field (**live-filtering**); arrow/Return routing goes
  through the search field's `moveDown(_:)`, `moveUp(_:)`, and
  `insertNewline(_:)` command selectors, dispatched via
  `PickerKeyboardController` (**arrow-and-return-routing**,
  **shared-keyboard-controller**). Escape is routed two ways: the search
  field's own `cancelOperation(_:)` command selector, and a window-level
  `NSEvent` local monitor installed in `viewDidAppear` and removed in
  `viewWillDisappear`; the monitor runs before the key event is dispatched
  to any responder and returns `nil` for a matched key-down, discarding
  it, so a single physical Escape keypress cannot also reach the search
  field's field editor to raise `cancelOperation(_:)` through
  `control(_:textView:doCommandBy:)` (**escape-routing**,
  **escape-idempotency**). The table sets `refusesFirstResponder = true`
  so the search field alone holds first-responder status once
  `focusSearchField()` is called (**search-field-focus**), sets
  `allowsMultipleSelection = false` even when `canPickMany` is true
  (**single-native-selection**), sets `headerView = nil`
  (**table-header**), and contains exactly one `NSTableColumn` with
  resizing mask `.autoresizingMask` and `columnAutoresizingStyle` set to
  `.firstColumnOnlyAutoresizingStyle` (**single-item-column**). The
  component's own `choose()` method implements **empty-choose** by reading
  `model.acceptedIndices()`, and `tableView(_:shouldSelectRow:)` returns
  `false` for a separator row (**separator-selection-guard**). Layer
  shaping: `root.wantsLayer = true` is set, but no `cornerRadius` or other
  layer shaping is configured. Typography and color are resolved through
  `ThemedLabel(role:textRole:)`, itself backed by
  `SemanticPalette.font(_:)` (`theme.typography.style(role).nsFont(scaledSize:)`);
  the table's background comes from `ThemedTableView` (role defaulting to
  `.surface`) with `tableScroll.drawsBackground = true`; the border is
  suppressed via `tableScroll.borderType = .noBorder`; the highlighted
  row's selection fill comes from `ThemedTableRowView`'s `.selection` role
  (4pt corner radius, inset 2pt/1pt); `tableView.rowHeight` is fixed at
  24pt. Accessibility roles are AppKit's stock defaults for
  `NSSearchField`, `NSTableView`, and `NSButton(checkboxWithTitle:)`; the
  checkbox is built as `NSButton(checkboxWithTitle: "", target: nil,
  action: nil)` and `ItemRowCellView` never calls
  `setAccessibilityLabel`/`setAccessibilityTitleUIElement` to link it to
  the row's title. `isEnabled` is never set on any control. Initial focus
  is triggered externally by `ExtensionPickerWindowController.takeInitialFocus()`.
- **WinUI 3**: Build the list with a `ListView` bound to the filtered
  items, each row a `DataTemplate` — a `Grid` with an optional `CheckBox`
  column (bound to a per-item `IsChecked` property mirroring
  `checkedIndices`, shown only when multi-select is active, mirroring
  `multi-select-checkbox`) and a `StackPanel` of `TextBlock`s for
  title/description/detail. Drive the search with a `TextBox` (or
  `AutoSuggestBox`) whose `TextChanged` event updates the filter on every
  keystroke, mirroring `live-filtering`; handle the `TextBox`'s
  `PreviewKeyDown` for Up/Down/Enter/Escape so focus stays in the
  `TextBox` rather than moving into the `ListView` — the WinUI analog of
  `refusesFirstResponder` plus `search-field-focus`. Set
  `ListView.SelectionMode="None"` and track "highlighted" as a bound index
  plus a custom `VisualStateManager` state on the `ListViewItem` container
  (a theme-brush-driven selection fill, mirroring `ThemedTableRowView`'s
  `.selection`-role rounded rect), rather than `ListView`'s own selection
  input gesture — `ListView` selects and closes on click by default,
  which would conflict with the source's rule that a click in multi-select
  toggles a checkbox and never closes the panel (`multi-select-click`);
  drive the checkbox/accept flow entirely from the row template's own
  click and `CheckBox.Checked`/`Unchecked` events instead. Bind every row
  color to a `ThemeResource` brush — never a `StaticResource` (which does
  not update on a theme change) or a literal `Color` — mirroring the
  source's `ThemeRole` indirection.

