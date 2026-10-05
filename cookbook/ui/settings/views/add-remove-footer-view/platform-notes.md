
- **SwiftUI**: An `HStack` with two `Button`s using `Image(systemName: "plus")` and `"minus"`, `.disabled(!canRemove)`, and a trailing `Spacer`.
- **Compose**: A `Row` of two `IconButton`s with `Icons.Default.Add` and `Remove` and `enabled = canRemove`, plus `Spacer(Modifier.weight(1f))`.
- **React/Web**: A `<div role="toolbar">` with two `<button aria-label>` elements and a flexible spacer; `disabled` follows the flag.
- **AppKit / UIKit (source)**: `ComposableSettings.AddRemoveFooterView` is an `@MainActor` `NSView` built on a horizontal `NSStackView` of spacing 4 and insets from `SettingsLayout.default[.rowSpacing]`. `addButton` and `removeButton` are small-square bezel buttons with the SF symbols plus and minus and descriptions Add and Remove; `onAdd` and `onRemove` are closures; `isRemoveEnabled` drives `removeButton`. `trailingView` takes the slack and `addAccessoryView` inserts before it. `init(accessibilityPrefix:)` sets the identifiers. It exists because a generic view controller cannot be an `NSButton` target.
- **WinUI 3**: A horizontal `StackPanel` with two `Button`s using `SymbolIcon` Add and Remove, `IsEnabled` bound to the flag, and `AutomationProperties.Name` set.

