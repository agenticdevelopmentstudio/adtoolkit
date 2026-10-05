
- **SwiftUI**: `HStack { Text(viewModel.title); Spacer();
  Text("\(value)").monospacedDigit(); Stepper("", value: $value, in:
  minValue...maxValue) }`, with `.labelsHidden()` on the `Stepper` since
  the leading `Text` already carries the title. Give the value `Text` an
  `.accessibilityHidden(true)` and instead attach
  `.accessibilityValue("\(value)")` to the `Stepper` itself, and
  `.accessibilityLabel(viewModel.title)` — closing the gap flagged in
  Label requirements, rather than reproducing it. Write to the bound
  state's setter with an equality guard before committing, mirroring
  skips-redundant-commits.
- **Compose**: A `Row` with `Text(title)` leading, then a monospaced
  `Text(value.toString())`, then two small `IconButton`s
  (`Icons.Default.KeyboardArrowUp`/`Down`) in place of a bare stepper —
  Compose has no built-in stepper control. Fix the step to `1`
  (mirroring fixes-stepper-increment), clamp against `minValue`/
  `maxValue` with no wraparound (mirroring disables-stepper-wraparound),
  and give the button pair a `Modifier.semantics { contentDescription =
  title }` and `stateDescription = value.toString()` — the Compose
  analog of the flagged missing accessibility link.
- **React/Web**: A flex row with a `<span>` title, a monospaced `<span>`
  showing the value, and a `<button>` pair (`aria-label="Decrease"`/
  `"Increase"`) or a native `<input type="number">` restricted to
  integer steps. Whichever control is used, wire `aria-labelledby` from
  the increment/decrement controls back to the title, and set
  `aria-valuenow`/`aria-valuemin`/`aria-valuemax` on a
  `role="spinbutton"` wrapper — the web analog of the accessibility link
  this source omits. Clamp at the bounds with no wraparound, mirroring
  disables-stepper-wraparound.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/StepperView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, inside
  the `ComposableSettings` namespace, conforming to
  `SettingsViewProtocol`. It composes a label, a monospaced value label,
  and an `NSStepper` into one row via `ComposableSettings.makeRow`/
  `pinToEdges`, wires the stepper's target/action to `stepperChanged(_:)`
  (wires-stepper-action), and keeps all three subviews synced to
  `RangeViewModel<Int>` on init and on `onChange`. It supports
  construction only through the view-model-taking initializer: both
  `init(coder:)` and the frame-only `init(frame:)` trigger a fatal error
  rather than producing an instance (rejects-coder-initialization,
  rejects-frame-only-initialization) — verifying this requires a
  death/exit test harness, or a compile-time API-surface check that the
  initializer is unavailable, not a normal in-process test assertion.
  There is no UIKit code path in source; a UIKit port would replace
  `NSStepper` with `UIStepper` (UIKit's direct analog — also arrows-only,
  no built-in value display) and the `target`/`action` pattern with
  `.addTarget(_:action:for: .valueChanged)`, still pairing it with a
  separate `UILabel` for the value the way this source pairs `NSStepper`
  with the value label. (Note: the frame-only initializer's fatal-error
  message string, `"init(frame frameRect: NSRect"`, is missing its
  closing parenthesis in source — a copy-paste artifact of the
  initializer's own signature, not a design choice; a port should write
  its own clear message rather than carry the typo forward.)
- **WinUI 3** (the reason this recipe exists): WinUI ships no bare,
  arrows-only stepper control equivalent to `NSStepper`/`UIStepper`. The
  closest concrete option is a `NumberBox` with
  `SpinButtonPlacementMode="Inline"`, `Minimum="{x:Bind MinValue}"`,
  `Maximum="{x:Bind MaxValue}"`, and `SmallChange="1"` (the direct
  analog of fixes-stepper-increment), laid out as a `Grid` with columns
  `*,Auto` — a `TextBlock` for the title in column 0, the `NumberBox` in
  column 1. Note the divergence from source: `NumberBox` always exposes
  an editable text field, unlike this source's read-only value label; if
  a non-editable value display is required instead, compose the row
  from a `TextBlock` (monospaced, via `FontFamily="Cascadia Mono"`) plus
  a vertical pair of small `RepeatButton`s (chevron-up/chevron-down
  glyphs) rather than `NumberBox`. Either way, set
  `AutomationProperties.Name`/`LabeledBy` on the interactive control(s)
  to the title `TextBlock` — the WinUI analog of the accessibility-title
  link this source's sibling rows have but this component itself is
  missing (see Label requirements); porting this component to WinUI is
  the moment to add it rather than carry the gap forward. Handle
  `NumberBox.ValueChanged` (or the `RepeatButton`s' `Click` events) to
  write the already-bounded, committed value with an equality guard
  before writing, mirroring skips-redundant-commits.

