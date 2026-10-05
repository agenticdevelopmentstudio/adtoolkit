
- **SwiftUI**: Compose an `HStack` with `Text(viewModel.title)`, a
  `Slider(value:in:)` bound to the current value, and a trailing
  `Text(formatter(value)).monospacedDigit()`. SwiftUI has no direct
  analog to `contentHuggingPriority`/`contentCompressionResistancePriority`
  as raw numbers; give the `Slider` no fixed frame (it already expands to
  fill the `HStack`'s remaining space, mirroring
  slider-expands-to-fill-remaining-width) and apply `.fixedSize()` (or
  `.layoutPriority(1)`) to the caption `Text` to mirror
  caption-never-compressed. Drive the caption from the `Binding`'s
  setter — called on every drag tick as the `Slider` writes through it —
  to mirror updates-caption-live; `onEditingChanged` fires only at the
  start and end of a drag, so it is the analog of the commit step
  (mirroring commits-slider-value/skips-redundant-commits), not of the
  live update.
- **Compose**: Use a `Row` with `Modifier.weight(1f)` on the `Slider` (the
  Compose analog of the low hugging priority) between a leading
  `Text(title)` and a trailing `Text(formatter(value))` styled with a
  tabular/monospace-figure font feature. Drive the trailing caption from
  the `Slider`'s `onValueChange` callback immediately (mirroring
  updates-caption-live), and commit to the backing state/view-model from
  the same callback with an equality check before writing, mirroring
  skips-redundant-commits.
- **React/Web**: A flex row (`display: flex; align-items: center`)
  containing a `<span>` for the title, an `<input type="range" min max
  value>` given `flex: 1` (mirroring slider-expands-to-fill-remaining-width),
  and a trailing `<span>` for the caption given `flex: 0 0 auto;
  white-space: nowrap` plus a tabular-nums font (mirroring
  caption-never-compressed and caption-uses-monospaced-digits). Update the
  caption text on the range input's `onInput` handler immediately, and
  commit the value upward via a controlled `value`/`onChange` prop pair,
  comparing against the previous value before calling the parent's setter
  to mirror skips-redundant-commits.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/CaptionedSliderView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`-isolated
  (the mechanism behind confines-to-ui-thread), inside the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`.
  It composes three subviews — an `NSTextField` label from
  `ComposableSettings.makeRowLabel`, an `NSSlider`, and a monospaced-digit
  `NSTextField` caption from `ComposableSettings.makeValueLabel
  (monospacedDigits: true)` — into one row via `ComposableSettings.makeRow`
  and `pinToEdges`, with the slider's horizontal content-hugging priority
  set to `1` (the mechanism behind
  slider-expands-to-fill-remaining-width) and the caption's horizontal
  compression resistance set to `.required` (the mechanism behind
  caption-never-compressed). Both inherited `NSView` initializers that
  could construct the view without a `viewModel`/`formatter` —
  `init(coder:)` and the frame-only `init(frame:)` — are forced to
  fatal-error, leaving `init(viewModel:formatter:)` as the only usable
  initializer; this is the mechanism behind
  requires-view-model-and-formatter-at-construction. There is no UIKit
  code path in source; a UIKit port would replace `NSSlider`/`NSTextField`
  with `UISlider`/`UILabel` and the `target`/`action` pattern with
  `.addTarget(_:action:for: .valueChanged)` — UIKit has no `NSCoder`-vs-frame
  initializer split to fatal-error on both the way the source's two
  initializers do.
- **WinUI 3**: Build the row as a `Grid`
  with column definitions `Auto,*,Auto`: a `TextBlock` for the title in
  column 0; a `Slider Minimum="{min}" Maximum="{max}"
  Value="{x:Bind Value, Mode=TwoWay}" HorizontalAlignment="Stretch"` in
  column 1 (the `*` column is the WinUI analog of the `1`-priority
  hugging — it lets the `Slider` claim the width left over after the
  `Auto`-sized title and caption columns); a trailing `TextBlock` bound to
  a formatted string (via an `IValueConverter` mirroring `formatter`) in
  column 2, whose `Auto` column width is the WinUI analog of
  caption-resists-compression (the column, and so the `TextBlock`, is
  never compressed below its content). Use the `Slider`'s `ValueChanged`
  event handler — not only the two-way `x:Bind` — to update the caption
  `TextBlock` immediately on every drag tick, mirroring
  updates-caption-live; write the committed value through a property
  setter that skips the assignment (and so skips raising
  `INotifyPropertyChanged`) when the incoming value already equals the
  current value, mirroring skips-redundant-commits.

