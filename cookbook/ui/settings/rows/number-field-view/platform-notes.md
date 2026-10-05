
- **SwiftUI**: `TextField("", value: $numericValue, format: .number)` (or a
  `String`-backed `TextField` with a manual parse/format pair, to reproduce
  the locale-invariant-write/locale-aware-read asymmetry) inside an
  `HStack` with a leading `Text(viewModel.title)`, giving the field a fixed
  `.frame(width:)` matching `fieldWidth` and `.font(.system(.body, design:
  .monospaced))` for the code-role font. Commit and clamp from the
  `Binding`'s setter (or `.onSubmit`) rather than on every keystroke,
  mirroring commits-on-editing-end and reverts-on-unparseable-text;
  SwiftUI's own `FocusState` change is the analog of
  `controlTextDidEndEditing`.
- **Compose**: `OutlinedTextField`/`BasicTextField` with
  `keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)`, a
  leading `Text(title)`, and a `Modifier.width(...)` matching `fieldWidth`.
  Keep `onValueChange` parsing against a `String` buffer only (coercing to
  the numeric type on every keystroke would fight a user mid-edit, the same
  problem the source's no-formatter comment describes), and commit/clamp
  when focus is lost (`Modifier.onFocusChanged`), mirroring
  commits-on-editing-end.
- **React/Web**: `<input type="text" inputMode="decimal">` (not
  `type="number"`, whose native spinner and silent-empty-on-invalid behavior
  diverges from the source's explicit revert-on-invalid path, and no
  `pattern` attribute, which cannot express the source's locale-aware
  grammar — a locale-invariant-only pattern like `-?[0-9]*\.?[0-9]*` would
  reject comma-decimal locales and would also accept a fraction for the
  integer case) paired with a `<label>` wired via
  `aria-labelledby`/`htmlFor`, the web analog of
  `setAccessibilityTitleUIElement`. Parse and clamp on `blur`/`Enter`
  (mirroring commits-on-editing-end and commits-on-field-action), reverting
  the displayed text on a parse failure rather than accepting it, using the
  same two thin parse/format functions per type (rather than the `pattern`
  attribute) to police what each type accepts — the same generalization the
  number value contract gives the Swift source.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/NumberFieldView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, generic
  over `Value: SettingsNumberValue`, inside the `ComposableSettings`
  namespace, conforming to `SettingsViewProtocol` and
  `NSTextFieldDelegate`. It supports construction only through its
  designated initializer: both `init(coder:)` and the frame-only
  `init(frame:)` trigger a fatal error rather than producing an instance.
  It wires `textField.target`/`textField.action` to itself and
  `fieldChanged(_:)`, and sets `textField.delegate` to itself, so that a
  field action and `controlTextDidEndEditing(_:)` both drive `commit()`; it
  attaches no `NSFormatter`. The same file declares the
  `SettingsNumberValue` protocol and its `Int`/`Double` conformances, each
  supplying a POSIX-first, then locale-`NumberFormatter`-based parse and a
  canonical `settingsFieldString`. The locale-aware parse configures a
  `.decimal`-style `NumberFormatter` with `allowsFloats` set from
  `settingsAllowsFloats`, and requires the formatter's consumed range to
  cover the entire string. The `Int` conformance additionally rejects a
  parsed magnitude that is not exactly representable as `Int`, via
  `Int.settingsExactInt(from:)`'s finite/whole-number/`Decimal`-equality
  check — guarding against the silent saturation `NSNumber.int64Value`
  would otherwise perform on overflow, and against the false positive a
  `Double`-based magnitude check would produce at `Int64.max` (which rounds
  up to exactly 2^63 as a `Double`). There is no UIKit code path in source;
  a UIKit port would replace `NSTextField` with `UITextField`
  (`keyboardType = .numbersAndPunctuation` to allow a leading `-` and a
  decimal separator), replace target/action with
  `.addTarget(_:action:for: .editingDidEnd)`, and reimplement the generic
  `SettingsNumberValue`-driven parse/clamp/revert logic against
  `UITextField.text` — UIKit has no `NSCoder`-vs-frame initializer split to
  fatal-error on the way the source's designated-initializer-only
  construction rule does.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `Auto,*` — a `TextBlock` for the title in column
  0, and a `NumberBox` — WinUI's purpose-built numeric field — in column 1,
  in place of a raw `TextBox`. Because `NumberBox.Value` is always a
  `double`, an integer-typed field (mirroring this recipe's `Int`
  conformance) MUST convert at the boundary with the same exactness check
  `Int.settingsExactInt(from:)` performs, rejecting (via
  `NumberBox.ValidationMode`/a `NumberBoxNumberFormatter` override) any
  value the round trip through `double` would not reproduce exactly; a
  floating-point-typed field maps directly. `NumberBox` already exposes
  `Minimum`/`Maximum` properties that map directly to this component's
  `minimum`/`maximum` when set; their own unset defaults are
  `double.MinValue`/`double.MaxValue` (not `NaN`), which already mirrors
  the no-clamp-at-that-end behavior of an unset bound with no extra
  sentinel needed. `NumberBox` has no equivalent of
  **skips-clamp-on-contradictory-bounds**, though: it documents no escape
  hatch for a caller-supplied `Minimum > Maximum`, so a port either
  validates that bounds are non-contradictory before setting them or
  accepts that `NumberBox`'s own (unspecified) behavior governs that case
  instead of this source's unclamped fallback — the two diverge there.
  `NumberBox` also parses its displayed text in the current culture only,
  with no locale-invariant-first fallback, so the round-trip guarantee
  behind this source's locale-invariant-first Design Decision (text this
  component itself wrote is guaranteed to read back correctly regardless of
  a later locale change) does not carry over automatically; a port that
  needs it must format and re-parse `NumberBox.Text` itself with the same
  locale-invariant-first-then-current-culture ordering rather than relying
  on `NumberBox`'s own culture-aware parsing. Setting
  `SpinButtonPlacementMode="Collapsed"` keeps it visually a bare field
  rather than a stepper. Set `NumberBox.ValidationMode=
  "InvalidInputOverwritten"` to reproduce reverts-on-unparseable-text
  (WinUI overwrites the box with the last valid value on an invalid commit,
  the same behavior as this source's `sync()` revert), and handle the
  `ValueChanged` event to write the already-clamped, committed value into
  the bound setting with an equality guard before writing, mirroring
  skips-redundant-commits. Set `AutomationProperties.LabeledBy` on the
  `NumberBox` to the `TextBlock`, the WinUI analog of
  `setAccessibilityTitleUIElement`. Give `NumberBox` a fixed `Width`
  matching `fieldWidth` (72 by default here) rather than letting it stretch
  to fill its column, the WinUI analog of fixes-field-width.

