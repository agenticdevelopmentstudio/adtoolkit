
- **SwiftUI**: Replace with a `Picker(viewModel.title, selection: $value)`
  built from `ForEach(viewModel.choices, id: \.value)` rows, each branching
  on `choice.imageSystemName`: `Label(choice.label, systemImage:
  symbolName)` when it is non-`nil`, or plain `Text(choice.label)` when it
  is `nil` — never `systemImage: choice.imageSystemName ?? ""`, since an
  empty symbol name renders a broken image — with `.pickerStyle(.menu)` to
  match the borderless popup affordance; wrap it
  with a leading `Text(viewModel.title)` in an `HStack` (or a
  `LabeledContent`) if the row shape from `makeRow` should be kept
  literally rather than relying on `Picker`'s own built-in label. Commit
  the selection to the underlying setting from the `Binding`'s setter with
  an equality guard, mirroring skips-redundant-commits; a selection whose
  raw value doesn't decode to a known choice mirrors
  ignores-unresolvable-selection by leaving the setting unchanged.
- **Compose**: Use an `ExposedDropdownMenuBox` (or a plain `Row` opening a
  `DropdownMenu`) with a leading `Text(title)` and a trailing read-only
  field/anchor showing the current choice's label; each `DropdownMenuItem`
  renders `choice.label`, with an optional leading `Icon` when an icon
  resource is supplied (the Compose analog of `imageSystemName`). Commit
  the tapped item's value to the backing state/view-model in
  `onClick`/`onItemSelected` with an equality check before writing,
  mirroring skips-redundant-commits, and leave the state unchanged if the
  clicked item's value can't be resolved, mirroring
  ignores-unresolvable-selection.
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title and
  a `<select>` whose `<option>` elements are built from `choices` (value =
  the choice's serialized value, text = `choice.label`), with the
  `<select>`'s `aria-labelledby` (or an explicit `<label for>`) pointing at
  the title `<label>`'s `id` — the web analog of
  `setAccessibilityTitleUIElement`. Commit the new value on the `<select>`'s
  `onChange` handler, comparing against the previous value before calling
  the parent's setter to mirror skips-redundant-commits, and ignoring a
  value that doesn't map to a known option to mirror
  ignores-unresolvable-selection.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/PopupMenuChoiceView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, generic
  over `Value: Codable & Sendable & Equatable`, inside the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`. It
  composes two subviews — an `NSTextField` label from
  `ComposableSettings.makeRowLabel` and a borderless `NSPopUpButton`
  populated from `ChoiceViewModel.choices` — into one row via
  `ComposableSettings.makeRow` and `pinToEdges`. Per added item,
  **attaches-choice-value-to-item** is implemented by setting
  `representedObject` to `choice.value`, and **attaches-choice-image** by
  setting `image` to `NSImage(systemSymbolName: choice.imageSystemName,
  accessibilityDescription: nil)` when non-`nil`.
  **suppresses-popup-bezel** is `popUpButton.isBordered = false`;
  **resists-popup-stretch** is
  `popUpButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)`.
  **links-popup-accessibility-title** is
  `popUpButton.setAccessibilityTitleUIElement(label)`.
  **wires-popup-action** sets `popUpButton.target` to `self` and
  `popUpButton.action` to `Selector("popupChanged:")`, whose handler reads
  `sender.selectedItem?.representedObject as? Value`, guarding on the cast
  to implement **ignores-unresolvable-selection**, and on an equality check
  against `settingObserver.value` to implement **skips-redundant-commits**
  before writing (**commits-selection-value**). It supports construction
  only through the `viewModel`-taking initializer: both `init(coder:)` and
  the frame-only `init(frame:)` trigger a fatal error rather than
  producing an instance, and the type is `@MainActor`-isolated, so the
  compiler rejects construction or mutation of `self` from off the main
  actor. There is no UIKit code path in source; a UIKit port would replace
  `NSPopUpButton` with a `UIButton` presenting a `UIMenu` (or a
  `UIPickerView`) and the `target`/`action` pattern with
  `.addTarget(_:action:for: .primaryActionTriggered)` or a `UIAction`
  handler per menu item. `UIView` inherits the same
  `init(coder:)`-vs-`init(frame:)` split that `NSView` does — a UIKit port
  would fatal-error both initializers the same way this source's
  designated-initializer-only construction rule does.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `*,Auto`: a `TextBlock` for the title in column 0
  (the `*` column lets the title claim the row's leading space, the WinUI
  analog of `makeRow`'s flexible spacer sitting between the label and the
  control); a `ComboBox` in column 1, `HorizontalAlignment="Right"`, styled
  without its default border/background (`BorderThickness="0"`,
  `Background="Transparent"`) to match `isBordered = false`'s bezel-less
  popup. Bind `ItemsSource` to the `choices` collection with
  `DisplayMemberPath="Label"` and `SelectedValuePath="Value"` (the WinUI
  analog of a menu item's title and `representedObject`); when a choice
  carries an icon, replace the plain `DisplayMemberPath` binding with a
  `ComboBoxItem` `DataTemplate` containing a `StackPanel` of a `FontIcon`
  (bound to the choice's icon glyph) followed by a `TextBlock` for
  `Label`, the WinUI analog of `NSImage(systemSymbolName:)`. Set
  `AutomationProperties.LabeledBy` on the `ComboBox` to the `TextBlock` —
  the WinUI analog of `setAccessibilityTitleUIElement` linking a bare
  control's name to its visible label. Commit the selection from
  `SelectionChanged`, first checking `SelectedValue` resolves to a known
  choice value (mirroring ignores-unresolvable-selection) and only
  then writing through a property setter that skips the assignment (and so
  skips raising `INotifyPropertyChanged`) when the incoming value already
  equals the current value, mirroring skips-redundant-commits.

