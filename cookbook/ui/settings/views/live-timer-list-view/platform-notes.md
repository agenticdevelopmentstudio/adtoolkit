
- **SwiftUI**: A `ForEach` over timers keyed by id inside a `TimelineView` that pauses while the scene is inactive (`scenePhase`).
- **Compose**: A `LazyColumn` with `key = { it.id }` and a tick effect gated by `LocalLifecycleOwner` resumed state.
- **React/Web**: A keyed list rendering plus a `setInterval` gated by the Page Visibility API and an `IntersectionObserver`.
- **AppKit / UIKit (source)**: `ComposableSettings.LiveTimerListView` is an `@MainActor` `NSView` holding a vertical `NSStackView` of spacing 8, an empty `ThemedLabel` and `LiveTimerRowView`s. `windowIsVisible` defaults to `window.occlusionState.contains(.visible)` and observes `NSWindow.didChangeOcclusionStateNotification` from `viewDidMoveToWindow`. `visibilityChanged()` starts or stops the owned `LiveTimerTicker` and ticks at once when seen. `setTimers(_:)` keeps rows in a dictionary keyed by id.
- **WinUI 3**: A `ListView` keyed by id with a `DispatcherTimer` started and stopped on `Window.VisibilityChanged` and `Window.Activated`.

