
- **SwiftUI**: There is no SwiftUI equivalent of a single, app-wide local
  `NSEvent` monitor, so the click/pointer capture still has to happen at
  whatever AppKit-hosting layer wraps the SwiftUI content. Model the tracker
  itself as a single, app-wide `ObservableObject` — mirroring
  `ComposableTabsActivePane.shared`, one instance keyed internally by window,
  not one instance per window/scene — exposed via `.environmentObject`, and
  give each pane a modifier that reads its own `nodeID` against the tracker's
  `activeNodeID(in:)` to pick `.overlay(Rectangle().strokeBorder(color, lineWidth: 2))`,
  so the stroke stays inside the edge the way the inset border does here,
  where `color` switches between the accent and hairline tokens exactly as
  `applyTheme(_:)` does.
- **Compose (Desktop)**: Compose Desktop's `Window` maps closely to `NSWindow`,
  so hold the active-pane map as a `MutableState<UUID?>` per `Window`
  (hoisted in a `CompositionLocal`, one per window scope). Use
  `Modifier.onPointerEvent(PointerEventType.Press)` for the click path and
  `Modifier.onPointerEvent(PointerEventType.Move)` gated by the equivalent
  setting for the pointer-follows path, and `Modifier.border(2.dp, if (isActive) accent else outline)`
  for the outline, matching the always-2pt, color-only distinction this file
  draws.
- **React/Web**: The web platform has effectively one window, so the
  per-window map collapses to a single ref/state value held by an
  `ActivePaneProvider` context. Attach `mousedown`/pointer-move listeners at
  the document root in the capture phase (mirroring the one local monitor
  here, instead of one listener per pane) and toggle a `data-active`
  attribute or CSS class on the pane element to switch its outline color;
  gate pointer-move-driven switching behind a user preference the same way
  `activePaneFollowsMouse` gates it here.
- **AppKit/UIKit**: This is the source platform; see
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsActivePane.swift`.
  It is macOS-only — `NSEvent` local monitors, `NSWindow.firstResponder`/
  `makeFirstResponder`, weak `NSHashTable` collections, and
  `NSWindow.didBecomeKeyNotification`/`didResignKeyNotification` all have no
  UIKit equivalent. UIKit has no local-monitor concept and (outside iPad
  multi-window) no second window competing for keyboard focus in the same
  sense; a port to iPad multi-window would need `UIGestureRecognizer`s or a
  `UIWindow.hitTest` override plus a walk up the `UIResponder.next` chain in
  place of the `NSEvent` monitor and `makeFirstResponder` walk used here. The
  main-queue-versus-run-loop-mode distinction behind
  **close-and-highlight-changes-dispatch-through-the-main-queue** is
  `DispatchQueue.main` (drained in every run-loop mode) versus `RunLoop.main`
  (enqueued only in `.default` mode, so it would stall while the platform
  tracks a mouse-down in `.eventTracking` mode).
- **WinUI 3**: Track the active pane per `Window` (WinUI 3's per-window model
  matches `NSWindow` closely) in a `Dictionary<Window, Guid>`, mutated only
  from the UI thread — WinUI is single-threaded per dispatcher, matching this
  file's confinement to one thread — and remove a window's entry when its
  `Window.Closed` event fires, mirroring how the source clears
  `activeByWindow` on `NSWindow.willCloseNotification` (see
  **close-and-highlight-changes-dispatch-through-the-main-queue** and
  **window-close-clears-active-id-silently**) rather than relying on garbage
  collection to age the entry out — `Guid` is a value type, so a
  `ConditionalWeakTable` cannot hold it directly the way the source's weak
  `NSHashTable`s hold reference types. Replace the `NSEvent` local monitor with a
  `PointerPressed` handler added at the `Window.Content` root via the
  `AddHandler` overload that takes `handledEventsToo: true`, so a click is
  still seen even if an inner control already marked it handled — the WinUI
  analogue of a monitor that "sees the events before the responder chain
  does." Gate a matching root-level `PointerMoved` handler behind a setting
  equivalent to `activePaneFollowsMouse`, and behind `Window.Activated`
  state (`WindowActivationState.Deactivated` in place of "not key") and a
  check for an open modal in place of an attached sheet. For the focus walk,
  use `FocusManager.TryMoveFocusAsync`/`Control.Focus(FocusState.Programmatic)`
  starting from the hit-tested element and walking outward through its
  `VisualTreeHelper` ancestry, mirroring the innermost-first order taking
  focus uses; handle `Control.LosingFocus` with `args.Cancel = true` as
  WinUI's equivalent of a responder refusing to resign, and check that flag
  before calling the WinUI equivalent of `activate` — mirroring
  **focus-refusal-blocks-mouse-moved-activation**. For the chrome, wrap each
  pane's content in a `Border BorderThickness="2"` bound to a
  `SolidColorBrush` resource that switches between the app's accent brush and
  a neutral outline brush via a view-model boolean exactly like `isActive`
  here, and inset the pane's own background `Border`/`Grid` by 2px from that
  outer `Border`'s edge to reproduce `borderInset`.
- **UI-thread confinement**: `confines-to-ui-thread` — the tracker and the pane backdrop are both declared `@MainActor`, so use from off the main actor fails to compile.

