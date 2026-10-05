
- **SwiftUI**: Model presentation state (`isPresented`, indeterminate vs.
  determinate, the headline string) in an `ObservableObject`, and drive it
  from a `ProgressView()` (indeterminate) that switches to
  `ProgressView(value: 1, total: 1)` when finished, hosted in a small
  auxiliary window or `NSHostingView`-backed panel rather than a SwiftUI
  `Window` scene, since a `Window` scene cannot reproduce
  `becomesKeyOnlyIfNeeded`/`orderFrontRegardless` semantics on its own. Use
  `Task { try? await Task.sleep(for: .seconds(1)) }` in place of
  `DispatchQueue.main.asyncAfter`, and keep the presenting object retained
  by that `Task` (or by the view model) for the same reason `self` is
  captured strongly in the source.
- **Compose**: There is no Compose Desktop equivalent of an AppKit utility
  panel that floats above other windows without taking focus; approximate it
  with a small, undecorated `androidx.compose.ui.window.Window` (or a
  non-modal `Dialog` with `focusable = false` in its `DialogProperties`) to
  approximate `becomesKeyOnlyIfNeeded`. Use a `CircularProgressIndicator()`
  (indeterminate) that switches to `CircularProgressIndicator(progress = {
  1f })` on completion, and use a `kotlinx.coroutines.delay(1000)` inside a
  `CoroutineScope` owned by the panel itself (not by the caller) before
  closing it, to reproduce the deliberate strong-capture lifetime.
- **React/Web**: Port as a small, fixed-position, non-modal status element
  (a `div` with `role="status"`, not a native `<dialog>`, since `<dialog>`
  implies modal semantics this component deliberately avoids) containing a
  spinner and the headline text, swapped for a "Scan complete" state on
  finish. Use `setTimeout(..., 1000)` to remove it from the DOM; because a
  JavaScript closure keeps its captured variables alive by default, there is
  no weak-capture failure mode to reproduce, but a cleanup effect (e.g. a
  React `useEffect` teardown) MUST NOT clear that timer early, or the panel
  will never disappear.
- **AppKit / UIKit**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectScanProgressWindow.swift`,
  using `NSWindowController`, `NSPanel`, `NSProgressIndicator`,
  `NSStackView`, `NSLayoutConstraint`, and `DispatchQueue.main.asyncAfter`,
  plus two components from the project's shared AppKit UI toolkit,
  `ThemedLabel` and `ThemedBackgroundView`, and an `accessibilityID(_:)`
  helper for identifier assignment. The type is declared `@MainActor`, so
  `init()`, `present()`, `finish()`, and its `headline` and `bar`
  properties can only be called or accessed from the main actor — a call
  from off the main actor fails to compile unless awaited across an
  isolation boundary. The window is constructed as an `NSPanel` with a
  content rect of 240 by 72 points, a style mask of `.titled` and
  `.utilityWindow`, `backing: .buffered`, and `defer: false`;
  `isFloatingPanel` is set to `true` and `hidesOnDeactivate` to `false`;
  `becomesKeyOnlyIfNeeded` is set to `true` so the panel can be ordered
  front via `orderFrontRegardless()` without ever becoming the key window.
  The progress indicator is configured with style `.bar`, `controlSize`
  `.small`, and `usesThreadedAnimation` `true`. `init?(coder:)` is marked
  unavailable and calls `fatalError` with the message "init(coder:) is not
  supported" if it is ever invoked, since this type is never loaded from a
  storyboard or XIB. The closure `finish()` passes to
  `DispatchQueue.main.asyncAfter(deadline: .now() + Self.lingerAfterFinishing)`
  captures `self` strongly, not weakly, so the panel outlives the caller's
  own reference to it long enough to close itself. UIKit has no equivalent
  of a separate, always-on-top utility window that does not take focus; a
  UIKit port would need a floating overlay `UIView` pinned within the
  current window's view hierarchy (e.g. a small banner anchored to a corner
  via Auto Layout) rather than a second `UIWindow`.
- **WinUI 3**: This is the platform this recipe exists to unblock. Represent
  the panel as a secondary `Window` (or `Microsoft.UI.Xaml.Window` opened via
  interop) whose native `HWND` owner is set to the main window's `HWND`
  through `WinRT.Interop.WindowNative.GetWindowHandle` plus
  `Microsoft.UI.Windowing.AppWindow.GetFromWindowId`/`SetOwner`, giving the
  same "floats above, closes with, but is not blocked by" relationship
  `isFloatingPanel` gives on AppKit. Show it without ever calling
  `Window.Activate()` — call the Win32 `ShowWindow` with `SW_SHOWNOACTIVATE`
  through interop instead — to reproduce `becomesKeyOnlyIfNeeded` and
  `orderFrontRegardless()`'s "visible but never key" behavior. Content is a
  XAML `ProgressBar` with `IsIndeterminate="True"` bound to a view model
  implementing `INotifyPropertyChanged`, alongside a `TextBlock` bound to the
  headline string; `finish()` flips `IsIndeterminate` to `false` and sets
  `Value` equal to `Maximum`. Use `await Task.Delay(TimeSpan.FromSeconds(1))`
  for the linger, then resume on the UI thread via
  `DispatcherQueue.TryEnqueue` before calling `Window.Close()` (a
  `Task.Delay` continuation does not automatically resume on the UI thread
  the way `DispatchQueue.main.asyncAfter` does). Keep a strong reference to
  the window instance across that awaited delay — in a field, not a local
  that can be collected — to reproduce the deliberate strong `self` capture
  in `finish()`; a weak reference here would let the window be
  garbage-collected before `Close()` runs, leaving it on screen exactly as
  the source's inline comment warns.
- **confines-to-ui-thread** (scope): The rule covers the window's construction, its present and finish operations, and its headline and progress-indicator state.

