
- **SwiftUI**: Replace with an `HStack` pairing `Text(viewModel.title)`
  leading and a trailing `SecureField("", text: $value)`, writing the
  binding's setter back into the underlying setting with an equality guard
  before assigning, mirroring **skips-redundant-commits**. Give the field an
  explicit `.accessibilityLabel(viewModel.title)` — the fix this recipe's
  Accessibility section flags as missing from the AppKit source — and drive
  its font/color from the same semantic theme tokens (`.body`, `primaryText`,
  `placeholderText`) rather than fixed literals, mirroring the theme styling
  documented for `TextEditView`.
- **Compose**: Use a `Row` with `Text(title)` leading and a trailing
  `OutlinedTextField(value = value, onValueChange = { ... },
  visualTransformation = PasswordVisualTransformation(), singleLine = true)`
  — `PasswordVisualTransformation` is Compose's dot-masking analog of
  `NSSecureTextField`. Commit to the backing state/view model on focus loss
  or `ImeAction.Done` (`KeyboardOptions(imeAction = ImeAction.Done)` with a
  `KeyboardActions.onDone`, or a `Modifier.onFocusChanged` check), not on
  every `onValueChange` call — `onValueChange` fires per keystroke, which
  would otherwise write partial secrets to storage — comparing against the
  previous value before writing, mirroring **skips-redundant-commits**. Give
  it `Modifier.semantics { contentDescription = title }` (the missing
  accessibility link's Compose analog).
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title and
  an `<input type="password">` whose `aria-labelledby` points at the title
  `<label>`'s `id` — the web analog of the accessibility link this recipe
  flags as missing from the source. Commit the new value on the input's
  `blur` handler (or Enter via `onKeyDown`), not on every `onChange` call —
  an `<input>` fires `onChange` per keystroke, which would otherwise write
  partial secrets to storage — comparing against the previous value before
  calling the parent's setter, mirroring **skips-redundant-commits**; style
  the input's font/color and any placeholder from theme tokens equivalent to
  `.body`/`primaryText`/`placeholderText`, mirroring the theme styling
  documented for `TextEditView`.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/SecureTextEditView.swift`
  — a macOS-only, `@MainActor`, `final` subclass of `TextEditView` inside the
  `ComposableSettings` namespace, overriding only
  `makeTextField(initialValue:)` to return `NSSecureTextField(string:
  initialValue)`. `final` is what forecloses further specialization (the
  requirement this recipe's Behavioral Requirements section defers to this
  entry): it makes `SecureTextEditView` the terminal specialization of
  `TextEditView` for masked entry, so the compiler rejects any attempt to
  declare a further subclass of it. The override requires `class func` (not
  `static`) because it overrides `TextEditView`'s `open class func
  makeTextField`, which trips SwiftLint's `static_over_final_class` rule
  (see Design Decisions). `TextEditView.swift`
  (`adtoolkit://cookbook/ui/settings/rows/text-edit-view`) supplies everything else — row
  layout, content-hugging, the `textFieldChanged(_:)` target/action commit
  path, `observeTheme` styling, and `viewModel.onChange` sync — and is out of
  this recipe's scope. There is no UIKit code path in source; a UIKit port
  would replace `NSSecureTextField` with a `UITextField` configured
  `isSecureTextEntry = true`, and would enforce "no further subclassing" (if
  desired) with a `final` class declaration, UIKit's own equivalent
  mechanism.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `Auto,*`: a `TextBlock` for the title in column 0
  and a `PasswordBox` — WinUI's own dot-masking control and the direct
  analog of `NSSecureTextField` — in column 1, `HorizontalAlignment="Stretch"`
  so the `*` column's leftover width goes to the field rather than the
  title, the WinUI analog of `expands-text-field-to-fill-row`. Set
  `AutomationProperties.LabeledBy` on the `PasswordBox` to the `TextBlock` —
  the WinUI analog of the `setAccessibilityTitleUIElement` link this recipe
  flags as missing from the AppKit source; add it in the port even though
  the source itself omits it. Commit on the `PasswordBox`'s `LostFocus`
  event (or Enter), not on every `PasswordChanged` event — `PasswordChanged`
  fires per keystroke, which would otherwise write partial secrets to
  storage (the keychain, in the typical setup) — writing through a property
  setter that skips the assignment (and so skips raising
  `INotifyPropertyChanged`) when the incoming value already equals the
  current one, mirroring **skips-redundant-commits**. Bind
  `PasswordBox.Foreground`/`PlaceholderForeground` to theme resource
  brushes equivalent to `primaryText`/`placeholderText`, mirroring the
  theme styling documented for `TextEditView`. Note `PasswordBox` ships its
  own built-in reveal-password toggle button, an affordance neither
  `NSSecureTextField` nor this source provides; carrying it over in the port
  is a platform enhancement, not something to gate on parity with the
  AppKit source.

