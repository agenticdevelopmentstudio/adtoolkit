
- **SwiftUI**: `VStack(spacing:)` is the direct equivalent, with `spacing`
  sourced from the equivalent of the group-spacing token. Unlike this
  component, which takes children imperatively via repeated
  add-arranged-view calls after construction, a `VStack` takes its
  children declaratively as trailing-closure content at the call site —
  there is no separate "add a child later" step to port, and no
  equivalent of a publicly exposed internal stack view is needed since
  `VStack` has no such wrapped sub-object.
- **Compose**: `Column(verticalArrangement = Arrangement.spacedBy(...))`,
  with the spacing value sourced from the equivalent of the group-spacing
  token. As with SwiftUI, Compose children are declared inline rather
  than appended imperatively after construction, so a port drops the
  add-arranged-view-style API entirely.
- **React/Web**: A `<div>` with `display: flex; flex-direction: column;
  gap: <groupSpacing>px;` (a CSS Flexbox column). The `gap` property
  supplies the equivalent of the internal stack's spacing directly, with
  no manual spacer elements needed; children are ordinary DOM children in
  document order, corresponding to the order arranged subviews are added.
- **AppKit / UIKit (source)**: `VerticalStackView.swift`
  (`packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/VerticalStackView.swift`)
  is a macOS-only (`import AppKit`), `@MainActor` `NSView` subclass
  conforming to `SettingsViewProtocol` (a marker protocol with no
  requirements of its own, so the conformance is recorded here rather than
  as a normative requirement). It sets
  `translatesAutoresizingMaskIntoConstraints = false` on itself and on its
  internal `NSStackView` (`orientation = .vertical`) — a pure Auto Layout
  framework construction rule with no equivalent step needed on a
  platform that never had a legacy autoresizing-mask/frame layout system
  to opt out of. It pins that stack view to all four edges of the outer
  `NSView` via `Self.pinToEdges(_:of:)` (`ViewLayout.swift`), exposes that
  wrapped stack view publicly as `stackView` (see Design Decisions), and
  exposes exactly one mutating method, `addArrangedSubview(_:)`, that
  forwards to it; the outer `NSView` itself renders nothing. The public
  `convenience init()` forwards to `init(frame: .zero)` with no
  parameters of its own; the designated `init(frame frameRect: NSRect)`
  discards the caller-supplied `frameRect` and always calls
  `super.init(frame: .zero)` (see Design Decisions); `required init?(coder:)`
  fatal-errors with the message `init(coder:) has not been implemented`
  (**rejects-deserializing-construction**). A UIKit port would use
  `UIStackView` directly (no wrapping `UIView` needed, since `UIStackView`
  is itself a `UIView`), making this wrapper layer unnecessary on that
  platform.
- **WinUI 3**: Use a `StackPanel` with `Orientation="Vertical"` and
  `Spacing` bound to the app's equivalent of the group-spacing layout
  token (WinUI's `StackPanel.Spacing` is the direct analog of the
  internal stack's spacing — no manual spacer elements needed, matching
  the React/Web note above). `StackPanel` has no enabled-driven visual
  states of its own to define in a visual-state group, since — like the
  source — it is a pure layout container with no interactive states (see
  States). Children are added via `panel.Children.Add(view)`, mirroring
  the add-arranged-view operation; because `StackPanel.Children` is
  already a public property on the framework type itself, a WinUI port
  gets the equivalent of this component's public internal-stack-view
  exposure for free, with no separate wrapper property needed. There is
  no WinUI equivalent needed for the source's edge-pinning step either,
  since a `StackPanel` placed directly in its parent (e.g. via `Grid`
  row/column stretch, or `HorizontalAlignment="Stretch"`/
  `VerticalAlignment="Stretch"`) already fills its allotted space without
  a separate constraint-activation step:
  ```xml
  <StackPanel Orientation="Vertical"
              Spacing="{StaticResource GroupSpacing}"
              HorizontalAlignment="Stretch"
              VerticalAlignment="Stretch"/>
  ```

