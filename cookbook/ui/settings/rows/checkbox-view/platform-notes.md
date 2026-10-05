
- **SwiftUI**: Replace with an `HStack` containing `Text(viewModel.title)`
  and a trailing `Toggle("", isOn: $isOn).labelsHidden()`, giving the
  `Toggle` an `.accessibilityLabel(viewModel.title)` (SwiftUI's analog of
  `setAccessibilityTitleUIElement`) so the switch announces the row's title
  rather than being unlabelled. Write the user's flips back into the
  underlying setting from the `Binding`'s setter with an equality guard,
  mirroring skips-redundant-commits.
- **Compose**: Use a `Row` with `Text(title)` leading and a trailing
  `Switch(checked = value, onCheckedChange = { ... })`. Give the `Switch` a
  `Modifier.semantics { contentDescription = title }` (the Compose analog
  of the title-element link), and commit to the backing state/view-model
  from `onCheckedChange` with an equality check before writing, mirroring
  skips-redundant-commits.
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title and
  an `<input type="checkbox" role="switch">` (or a styled switch component)
  whose `aria-labelledby` points at the title `<label>`'s `id` — the web
  analog of `setAccessibilityTitleUIElement`. Commit the new value on the
  input's `onChange` handler, comparing against the previous value before
  calling the parent's setter to mirror skips-redundant-commits.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/CheckboxView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`-isolated
  (the mechanism behind confines-to-ui-thread), inside the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`. It
  composes two subviews — an `NSTextField` label from
  `ComposableSettings.makeRowLabel` and an `NSSwitch` — into one row via
  `ComposableSettings.makeRow` and `pinToEdges`, links the switch's
  accessibility title to the label
  (`toggle.setAccessibilityTitleUIElement(label)`), and wires the switch's
  target/action (`toggle.target = self`, `toggle.action =
  #selector(toggleChanged(_:))`) — the AppKit plumbing behind
  **commits-toggle-value** — to `toggleChanged(_:)`. Both inherited `NSView`
  initializers that could construct the view without a `viewModel` —
  `init(coder:)` and the frame-only `init(frame:)` — are forced to
  fatal-error, leaving `init(with:)` as the only usable initializer; this is
  the mechanism behind requires-view-model-at-construction. There is no
  UIKit code path in source; a UIKit port would replace `NSSwitch` with
  `UISwitch` and the `target`/`action` pattern with
  `.addTarget(_:action:for: .valueChanged)` — UIKit has no `NSCoder`-vs-frame
  initializer split to fatal-error on both the way the source's two
  initializers do.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `*,Auto`: a `TextBlock` for the title in column 0
  (the `*` column lets the title claim the row's leading space, the WinUI
  analog of `makeRow`'s flexible spacer sitting between the label and the
  control); a `ToggleSwitch` (or `ToggleSwitch` restyled with
  `OnContent=""`/`OffContent=""` to read as a plain switch, matching
  `NSSwitch`'s minimal chrome) bound `IsOn="{x:Bind IsOn, Mode=TwoWay}"` in
  column 1, `HorizontalAlignment="Right"`. Set
  `AutomationProperties.LabeledBy` on the `ToggleSwitch` to the `TextBlock`
  — the WinUI analog of `setAccessibilityTitleUIElement` linking a bare
  control's name to its visible label. Write the committed value through a
  property setter that skips the assignment (and so skips raising
  `INotifyPropertyChanged`) when the incoming value already equals the
  current value, mirroring skips-redundant-commits. `ToggleSwitch`'s
  built-in `Toggled` event is the WinUI analog of `toggleChanged(_:)`.

