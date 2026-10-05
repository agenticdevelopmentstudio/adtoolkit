
- **SwiftUI**: `LabeledContent(title) { Text(value).monospacedDigit().textSelection(.enabled) }` is the direct equivalent.
- **Compose**: A `Row` with a `Text(title)` and a right-aligned `SelectionContainer { Text(value, fontFeatureSettings = "tnum") }`.
- **React/Web**: A `<div>` holding a label and an `<output>` with `font-variant-numeric: tabular-nums; text-align: right; user-select: text`, tied together with `aria-labelledby`.
- **AppKit / UIKit (source)**: `ComposableSettings.ValueRowView` is an `@MainActor` view conforming to `SettingsViewProtocol`, built from `makeRowLabel`, `makeValueLabel`, `makeRow` and `pinToEdges`. Both labels are `ThemedLabel`s exposed as `label` and `valueLabel`; `value` reads and writes `valueLabel.stringValue`. The value label is selectable, right-aligned, uses monospaced digits and has the title as its accessibility label. `init(coder:)` is unavailable.
- **WinUI 3**: A `Grid` with two `TextBlock`s, the second `HorizontalAlignment="Right"`, `IsTextSelectionEnabled="True"` and `FontFeatures` tabular numerals, with `AutomationProperties.Name` set to the title.

