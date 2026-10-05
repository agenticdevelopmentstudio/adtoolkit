
- **SwiftUI**: `Picker("", selection: $value) { ForEach(choices) { Text($0
  .label).tag($0.value) } }.pickerStyle(.radioGroup).labelsHidden()`,
  preceded by its own `Text(viewModel.title)` heading, is the closest native
  analog — `.radioGroup` is a macOS-only `Picker` style that renders one
  native radio button per case, matching `builds-one-radio-button-per-choice`
  directly. SwiftUI has no first-class axis toggle on `.radioGroup`, so
  matching `axis` requires composing custom `Toggle`-styled radio rows inside
  a `VStack`/`HStack` chosen by `axis`, rather than relying on the built-in
  style, when a horizontal layout is required. Commit the selection to the
  backing view model from the `Binding`'s setter with an equality guard,
  mirroring skips-redundant-commits.
- **Compose**: There is no Material 3 "radio group" composable; build a
  `Column`/`Row` (chosen by axis) of `RadioButton(selected = choice.value ==
  value, onClick = { ... })` each paired with a trailing `Text(choice.label)`,
  wrapped in `Modifier.selectableGroup()` on the container — the Compose
  analog of the group-to-heading accessibility linkage this component's
  source does not implement (see Accessibility). Guard the write with an
  equality check before calling the parent's setter, mirroring
  skips-redundant-commits.
- **React/Web**: A `<fieldset>` with a `<legend>{title}</legend>` — the
  direct web analog of the heading-to-group linkage this component's source
  does not implement (see Accessibility) — wrapping a flex container (`flex-direction: column` or
  `row` per axis) of `<input type="radio" name={groupName} value=...
  checked={...}>` elements, each paired with its own `<label>` set from
  `choice.label`. Giving every input the same `name` attribute is the web's
  own native mutual-exclusivity mechanism, the direct analog of the source
  platform's same-parent radio exclusivity noted in Edge Cases. Commit the
  new value on each input's `onChange`, comparing against the previous
  value first to mirror skips-redundant-commits.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/RadioButtonChoiceView.swift`.
  A macOS-only (`import AppKit`), generic-over-`Value` `NSView` subclass,
  isolated to the main actor via Swift's `@MainActor`, inside the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`. It
  composes a `ThemedLabel` heading (via `ComposableSettings.makeRowLabel`)
  and, for each choice, one native `.radio`-type `NSButton` built from
  `NSButton(radioButtonWithTitle:target:action:)` wired to the
  `radioChanged(_:)` action, into two nested `NSStackView`s
  (`controlsStack.orientation`/`.alignment` driven by `axis`) pinned via
  `pinToEdges` — unlike its sibling row views, it does not use
  `ComposableSettings.makeRow`. It supports construction only through the
  `viewModel`-taking initializer: both `init?(coder:)` and the frame-only
  `init(frame:)` trigger a fatal error rather than producing an instance
  (the frame-only override's message is the truncated string `init(frame
  frameRect: NSRect`, missing its closing parenthesis — see Design
  Decisions). Selection state is AppKit's `NSButton.state`
  (`.on`/`.off`); the `radioButtons` array is exposed as `public
  private(set)` so callers can read but not replace it. There is no UIKit
  code path in source; UIKit has no native radio-button control, so a port
  would need `UIButton`s manually toggled in a target/action handler
  (clearing every sibling's selected state before setting the tapped one),
  or a `UISegmentedControl`/checkmarked table rows as an alternate native
  composition.
- **WinUI 3** (the reason this recipe exists): Use the
  `Microsoft.UI.Xaml.Controls.RadioButtons` control directly — it is a
  near 1:1 analog of this component: its `Orientation` property
  (`Vertical`/`Horizontal`) is the direct WinUI equivalent of the `axis`
  parameter (mirroring lays-out-controls-along-axis and
  aligns-controls-stack-by-axis in one property, since `RadioButtons`
  handles the alignment difference between orientations internally), and its
  `Header` property is the direct analog of this component's heading
  `label` — critically, `RadioButtons.Header` is exposed to `UIA` as the
  group's accessible name automatically, which is the exact linkage this
  component's own source leaves unimplemented (see Accessibility). Bind
  `ItemsSource="{x:Bind Choices}"` with
  `DisplayMemberPath="Label"`, and `SelectedItem="{x:Bind SelectedChoice,
  Mode=TwoWay}"` through a property setter that skips the assignment (and so
  skips raising `INotifyPropertyChanged`) when the incoming value already
  equals the current one, mirroring skips-redundant-commits. `RadioButtons`'
  built-in `SelectionChanged` event is the WinUI analog of `radioChanged(_:)`.

