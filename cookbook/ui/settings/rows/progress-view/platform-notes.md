
- **SwiftUI**: Use SwiftUI's own `ProgressView` type (same name as this
  component, a different API) —
  `ProgressView(value: viewModel.progress, total: 100).progressViewStyle(.linear)`
  when `progress` is non-nil for a determinate bar, or
  `ProgressView().progressViewStyle(.linear)` when it's `nil`. The explicit
  `.progressViewStyle(.linear)` is required on both branches: on macOS a bare
  `ProgressView()` renders a circular spinner by default, not the source's
  `.bar` style. The explicit `total: 100` is required on the determinate
  branch: `ProgressView(value:)` normalizes against a `0...1` range by
  default, while `NSProgressIndicator`'s default range (and this recipe's
  `progress` values) is 0–100. SwiftUI already switches rendering based on
  whether `value` is `nil`, mirroring `apply(progress:)`'s branch. Read
  `viewModel.progress` directly from an `ObservableObject`/`Observable`-backed
  view model in the view body instead of a manual Combine `sink`, letting
  SwiftUI's own diffing replace **tracks-progress-changes** and the stored
  `cancellable`.
- **Compose**: Use `LinearProgressIndicator(progress = { it })` bound to a
  `0f..1f`-normalized value — divide the source's 0–100 `progress` by 100
  (`progress / 100f`, or by `maxValue − minValue` if a caller has changed
  those through the public `progressIndicator` property) — when `progress` is
  non-nil, or the no-argument
  `LinearProgressIndicator()` overload (Compose's built-in indeterminate
  animation) when it's `nil`. Compose Material3 already splits determinate
  and indeterminate into two separate composables rather than one mutable
  `isIndeterminate` flag the way `NSProgressIndicator` does, so the port
  chooses the composable per state instead of mutating a shared instance.
- **React/Web**: Use the native `<progress value={progress} max={100} />`
  element when `progress` is non-nil (browsers render an indeterminate
  track automatically when the `value` attribute is entirely omitted,
  mirroring the nil/indeterminate branch), or `<progress />` with no
  `value` for the `nil` case. A CSS-animated element gives full styling
  control if needed; if so, gate its animation behind a
  `prefers-reduced-motion` media query, since the browser's own native
  `<progress>` indeterminate animation is not something the port controls
  directly (see Accessibility Options).
- **AppKit / UIKit (source)**: `ProgressView.swift` is macOS-only (`import
  AppKit`) — there is no iOS/UIKit counterpart in this file. It wraps one
  `NSProgressIndicator` pinned edge-to-edge inside an `NSView`, driven by a
  Combine subscription to `ProgressViewModel.$progress`, with `init(frame:)`
  fatal-erroring with the message `init(frame frameRect: NSRect` (see
  Design Decisions) and `init?(coder:)` fatal-erroring with the message
  `init(coder:) has not been implemented`, rather than either being usable,
  and the whole type isolated to `@MainActor`. **uses-constraint-based-layout**
  is implemented by setting `translatesAutoresizingMaskIntoConstraints = false`
  on both `self` and `progressIndicator`; **continues-updates-while-retained**
  is implemented by holding the `viewModel.$progress` subscription in a
  stored `cancellable: AnyCancellable?` property for the view's lifetime. A
  UIKit port would need `UIProgressView`
  for the determinate case and `UIActivityIndicatorView` for the
  indeterminate case, since `UIProgressView` — unlike `NSProgressIndicator`
  — has no built-in indeterminate mode of its own; the nil/non-nil branch in
  `apply(progress:)` would need to swap between two different UIKit control
  types rather than flip one `isIndeterminate` flag.
- **WinUI 3**: Use a `ProgressBar` control.
  Bind `ProgressBar.Value` to the caller's progress number (a 0–100 scale,
  matching `NSProgressIndicator`'s own default `minValue`/`maxValue`) when
  it's non-nil, and set `ProgressBar.IsIndeterminate="True"` when it's
  `nil` — `ProgressBar`'s `IsIndeterminate` dependency property is the
  direct analog of `isIndeterminate` in source
  (**shows-determinate-bar-for-non-nil-progress** /
  **shows-indeterminate-animation-for-nil-progress**), giving one control
  both modes the same way `NSProgressIndicator` does. Drive it from an
  `x:Bind`/`INotifyPropertyChanged` view-model property shaped like
  `ProgressViewModel.progress` (a nullable double), updating `Value` and
  `IsIndeterminate` together in that property's setter — the direct analog
  of `apply(progress:)`. Host the `ProgressBar` in its own `Grid` cell with
  `HorizontalAlignment="Stretch"` and `VerticalAlignment="Stretch"` and no
  `Margin`, reproducing `pinToEdges`'s edge-to-edge, no-inset placement.
  `ProgressBar` has no `fatalError`-style initializer guard, so enforce
  "always construct with a view model" through a required constructor
  parameter or `x:Bind` requirement instead of a runtime crash on an unused
  inherited initializer. `ProgressBar`'s determinate visual defaults to the
  system accent color, giving the same "no color decision made by this
  component" outcome as `NSProgressIndicator`'s system chrome (see
  Appearance).

