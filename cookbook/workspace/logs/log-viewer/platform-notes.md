
- **SwiftUI**: A SwiftUI port would express the toolbar as an `HStack`
  (leading items, a `Spacer()`, then Pause/Clear `Button`s, a small
  `Circle().fill(...)` for the status dot, and `Text` for the label) above
  a `Divider()` above the hosted log view, with the state-indicator refresh
  expressed as a computed `(Color, String)` derived from
  `@ObservedObject`/`@Published` controller state, and the start/stop calls
  moved to `.onAppear`/`.onDisappear`.
- **Compose**: Start from a `Column` with a `Row` toolbar (leading items, a
  `Spacer`, `TextButton`s for Pause/Clear, a small circular `Box` for the
  dot, `Text` for the label), a `HorizontalDivider`, then the hosted log
  composable below. `isConnected`/`lastError`/`isPaused` become `StateFlow`
  fields on a `ViewModel`; `start()`/`stop()` map to a `DisposableEffect`
  keyed on composition entering/leaving, matching the view-appeared/
  view-about-to-disappear lifecycle.
- **React/Web**: The toolbar becomes a flex row (a leading slot, a flexible
  spacer, Pause/Clear `<button>`s, a small colored `<span>`/`<div>` circle
  for the dot, a status `<span>` for the label) above a `<hr>`/border-top
  divider above the log component. `isConnected`/`lastError`/`isPaused`
  become props or store fields driving the same three-way branch;
  `start()`/`stop()` map to a `useEffect` mount/unmount pair opening and
  closing the underlying stream (SSE/WebSocket).
- **AppKit / UIKit**: This is the source platform (AppKit/macOS). The
  component is `NSViewController`-based (`LogViewController`), pairing an
  `NSView`-based log view (`LogView`) with an `NSStackView` toolbar; the
  themed secondary button, themed separator view, themed label, and themed
  background view are `ThemedSecondaryButton`, `ThemedSeparatorView`,
  `ThemedLabel`, and `ThemedBackgroundView` respectively. The
  leading/trailing toolbar-item hooks are `leadingToolbarItems()` and
  `extraTrailingToolbarItems()`; the start/stop lifecycle hooks are
  `viewDidAppear`/`viewWillDisappear`. On iOS, `NSViewController` becomes
  `UIViewController`, `NSView`/`NSStackView` become `UIView`/`UIStackView`,
  and the four themed view types need UIKit counterparts;
  `viewDidAppear`/`viewWillDisappear` map directly to the
  identically-named `UIViewController` lifecycle methods, so the
  start/stop-on-lifecycle behavior ports unchanged. The log controller
  contract, `LogController`, is a `@MainActor`-isolated protocol, this
  component is itself `@MainActor`, and its `onStateChange` member is
  typed `(@MainActor () -> Void)?`, so the state refreshes described under
  Edge Cases (Concurrent access) are serialized via Swift's actor
  isolation. The reference implementation also marks its `NSCoder`-based
  initializer (`init(coder:)`) unavailable at compile time and calls
  `fatalError` if it is ever invoked at runtime — a Cocoa/Interface-Builder
  construction rule with no counterpart on platforms without an
  NSCoder-based storyboard/XIB system: a call to construct the controller
  that way fails to compile, or hits that `fatalError` at runtime if the
  unavailability check is somehow bypassed.
- **WinUI 3**: Model the whole component as a `UserControl`/`Page` whose
  root `Grid` has two `RowDefinition`s — a toolbar row fixed at
  `toolbarHeight`, and a log row set to `*` — separated by a
  `<Border BorderThickness="0,0,0,1">` standing in for the themed separator
  view. The toolbar is a `Grid` (or a `DockPanel`-style pair of
  `StackPanel`s) with one `HorizontalAlignment="Left"` panel for the
  leading toolbar items and one `HorizontalAlignment="Right"` panel
  holding the extra-trailing items, Pause/Clear `Button`s, a small
  `Ellipse` (`Width="8" Height="8"`, `Fill` bound to a `SolidColorBrush`
  chosen by the same three-way connection state) for the status dot, and a
  `TextBlock` whose `Text` and `ToolTipService.ToolTip` both bind to that
  same state string. Drive the `Connected`/`Connecting`/`Error` visuals and
  the Pause/Resume title through `VisualStateManager` states toggled from a
  bound view-model exposing the same connected/paused/last-error surface
  as the log controller contract, and start/stop the transport from the
  page's `Loaded`/`Unloaded` events, mirroring the view-appeared/
  view-about-to-disappear lifecycle.

