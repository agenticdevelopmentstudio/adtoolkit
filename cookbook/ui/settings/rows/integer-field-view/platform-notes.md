
- **SwiftUI**: `TextField("", value: $intValue, format: .number)` (or a
  `String`-backed `TextField` with a manual parse/format pair, to reproduce
  the POSIX-write/locale-read asymmetry) inside an `HStack` with a leading
  `Text(viewModel.title)`, giving the field a fixed `.frame(width:)`
  matching `fieldWidth` and `.font(.system(.body, design: .monospaced))`
  for the code-role font. Commit and clamp from the `Binding`'s setter (or
  `.onSubmit`) rather than on every keystroke, mirroring
  commits-on-editing-end and reverts-on-unparseable-text; SwiftUI's own
  `FocusState` change is the analog of `controlTextDidEndEditing`.
- **Compose**: `OutlinedTextField`/`BasicTextField` with
  `keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)`,
  a leading `Text(title)`, and a `Modifier.width(...)` matching
  `fieldWidth`. Keep `onValueChange` parsing against a `String` buffer only
  (coercing to `Int` on every keystroke would fight a user mid-edit, the
  same problem the source's no-formatter comment describes), and
  commit/clamp when focus is lost (`Modifier.onFocusChanged`), mirroring
  commits-on-editing-end.
- **React/Web**: `<input type="text" inputMode="numeric" pattern="-?[0-9]*">`
  (not `type="number"`, whose native spinner and silent-empty-on-invalid
  behavior diverges from the source's explicit revert-on-invalid path)
  paired with a `<label>` wired via `aria-labelledby`/`htmlFor`, the web
  analog of `setAccessibilityTitleUIElement`. Parse and clamp on
  `blur`/`Enter` (mirroring commits-on-editing-end and
  commits-on-field-action), reverting the displayed text on a parse
  failure rather than accepting it.
- **AppKit/UIKit** (source platform): Source files
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/IntegerFieldView.swift`
  and `.../Views/NumberFieldView.swift`. Both are macOS-only (`import
  AppKit`) `NSView` subclasses, `@MainActor`, inside the
  `ComposableSettings` namespace. `IntegerFieldView` composes and forwards
  entirely to a private `NumberFieldView<Int>`, which performs the actual
  layout (`makeRow`/`pinToEdges`), theming (`observeTheme`), and
  parsing/clamping/commit work described above. There is no UIKit code
  path in source; a UIKit port would replace `NSTextField` with
  `UITextField` (`keyboardType = .numbersAndPunctuation` to allow a
  leading `-`), replace target/action with
  `.addTarget(_:action:for: .editingDidEnd)`, and reimplement the generic
  `SettingsNumberValue`-driven parse/clamp/revert logic against
  `UITextField.text` — UIKit has no `NSCoder`-vs-frame initializer split to
  fatal-error on both the way the source's designated initializer does
  (the mechanism behind **requires-view-model-at-construction**):
  `init?(coder:)` and `init(frame:)` are both overridden to call
  `fatalError`, so the only surviving construction path is the designated
  `init(viewModel:)`.
- **WinUI 3**: Build the row as a `Grid` with column definitions `*,Auto`
  (the same shape the boolean-row recipe uses): a `TextBlock` for the title
  in column 0, and a `NumberBox` — WinUI's purpose-built numeric field — in
  column 1, in place of a raw `TextBox`. `NumberBox` already exposes
  `Minimum`/`Maximum` properties that map directly to this component's
  `minimum`/`maximum`, and setting `SpinButtonPlacementMode="Collapsed"`
  keeps it visually a bare field rather than a stepper, matching this
  source's "a slider/stepper is the wrong control" rationale. Set
  `NumberBox.ValidationMode="InvalidInputOverwritten"` to reproduce
  reverts-on-unparseable-text (WinUI overwrites the box with the last valid
  value on an invalid commit, the same behavior as this source's `sync()`
  revert), and handle the `ValueChanged` event to write the already-clamped,
  committed value into the bound setting with an equality guard before
  writing, mirroring skips-redundant-commits. Set
  `AutomationProperties.LabeledBy` on the `NumberBox` to the `TextBlock`,
  the WinUI analog of `setAccessibilityTitleUIElement`. Give `NumberBox` a
  fixed `Width` matching `fieldWidth` (52 by default here) rather than
  letting it stretch, since WinUI's `NumberBox` otherwise fills its column.
  Two divergences `NumberBox` does not close: it has no POSIX-first parse —
  its own locale-aware `NumberFormatter`-equivalent parsing has no fallback
  ordering to reproduce this source's
  parses-locale-aware-integer-text/POSIX-first behavior (see
  `adtoolkit://cookbook/ui/settings/rows/number-field-view#requirements/parses-posix-integer-first`),
  so a value written by this source's POSIX `settingsFieldString` can read
  differently under a non-en-US Windows locale; and `NumberBox.Minimum`/
  `Maximum`, when both set with `Minimum > Maximum`, has no documented
  skip-the-clamp behavior matching
  skips-clamp-on-contradictory-bounds (see
  `adtoolkit://cookbook/ui/settings/rows/number-field-view#requirements/skips-clamp-on-contradictory-bounds`)
  — a WinUI port needs an explicit `Minimum > Maximum` check before relying
  on `NumberBox`'s own clamping.

