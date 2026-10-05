
- **SwiftUI**: A `TextField` with a `FormatStyle.Currency` binding and validation on commit; a refusal resets the bound text.
- **Compose**: An `OutlinedTextField` with a `VisualTransformation` or parse-on-blur against a `NumberFormat.getCurrencyInstance`, resetting on refusal.
- **React/Web**: An `<input inputmode="decimal">` parsed with `Intl.NumberFormat` on blur; on refusal reset the value, and set `placeholder` for the fallback.
- **AppKit / UIKit (source)**: `ComposableSettings.MoneyFieldView` is an `@MainActor` `NSView` wrapping a `TextEditView` driven by a `ViewModel<String>` whose getter formats through `formatter().editableString(cents:)` and whose setter calls the static `parse(_:formatter:range:allowsBlank:)` and writes only an accepted result. `parse` returns a double optional: nil for refusal, `.some(nil)` for an accepted blank. `refresh()` and `revert()` re-read the value and update the placeholder. It conforms to `ExplainedSettingsView`; `init(frame:)` and `init(coder:)` trap.
- **WinUI 3**: A `TextBox` with a converter based on `Windows.Globalization.NumberFormatting.CurrencyFormatter`, validating on `LostFocus` and restoring the stored text on failure; `PlaceholderText` carries the fallback.

