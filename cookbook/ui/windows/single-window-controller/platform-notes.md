
- **SwiftUI (`WindowGroup`/`Window` scenes)**: SwiftUI's native window scenes
  handle lazy creation and frame restoration declaratively; a SwiftUI
  equivalent would express the window ID as a scene identifier and rely on
  `@SceneStorage`/`defaultPosition`/`defaultSize` modifiers rather than an
  imperative window-controller subclass.
- **Jetpack Compose (Desktop)**: `Window`/`DialogWindow` composables with
  `rememberWindowState` provide the closest analog to persisted frame state;
  content-hugging resize would be expressed by observing content size in a
  `SubcomposeLayout` and calling `WindowState.size = ...`.
- **React / Web**: Not applicable in the same sense — a browser tab/window is
  not directly resizable or positionable by page script in the general case;
  an Electron/Tauri shell would map this recipe onto `BrowserWindow`
  geometry-persistence APIs instead.
- **AppKit (source platform)**: This recipe is extracted directly from the
  AppKit implementation, where the base class is `SingleWindowController`, an
  `open`, `@MainActor`-isolated `NSWindowController` / `NSWindowDelegate`
  subclass. "A utility-style window" is `NSPanel`, selected when
  `windowStyleMask` contains `.utilityWindow` or `.hudWindow`; otherwise
  `loadWindow()` builds a plain `NSWindow`. "Archive-based construction" is
  Cocoa's `NSCoder`-based `init?(coder:)`, marked
  `@available(*, unavailable)` here (a compile-time error), fatal if ever
  reached at runtime despite that. The window registry is
  `WindowManager.shared.registry`; the window frame manager is
  `WindowFrameManager`, reached through the `windowSpec` computed property
  `WindowFrameManager.swift` adds to this class in an extension. The
  accessibility identifier is produced by `AccessibilityID.slug(_:)`; the
  toolbar-buttons setting is `WindowSpec.toolbarButtons`, an option set
  masking `NSWindow.standardWindowButton` visibility. "Forcing the window
  fully to front" is `window?.orderFrontRegardless()`; quiet presentation
  calls `window.sinkBehindDesktop()` then `window.orderBack(nil)`, with no
  `NSApp.activate(ignoringOtherApps:)` call — `SingletonWindowController
  .present()` separately calls `NSApplication.activateUnlessQuiet()` to
  avoid stealing app-wide focus. The window's opacity is `alphaValue`; the
  floating level is `NSWindow.Level.floating` vs `.normal`. The
  single-instance protocol is `SingletonWindowController`, providing
  `ensureCurrent()`, `present()`, and `isOpen()` from a protocol extension
  over a conforming type's `static var current` and `static func
  makeShared()`. The reduce-transparency accessibility setting is
  `NSWorkspace.accessibilityDisplayShouldReduceTransparency`, which this
  class does not observe. The recent-document API is
  `NSDocumentController.shared.noteNewRecentDocumentURL`, called from
  `WindowManager.windowDidInteract(_:kind:)`. The content-refit machinery's
  private implementation names — `isApplyingContentFit` (reentrancy guard),
  `wantsRefitAfterMove` (computed gate), `moveRefitSettleTask` /
  `scheduleContentRefitAfterMove()` (the debounce timer, checking
  `NSEvent.pressedMouseButtons`), and the reused `FrameAnchors` (anchor-hold
  state) — are internal to this class; only their observable effects are
  asserted above.
- **WinUI 3 / Windows App SDK**: This recipe exists specifically to give the
  Windows port a single-instance-window equivalent base. A `Microsoft
  .UI.Xaml.Window` subclass would map `defaultSize`/`minSize` to
  `AppWindow.Resize`/`AppWindow.MinSize` (or `OverlappedPresenter`
  constraints), frame persistence to `ApplicationData.LocalSettings` keyed by
  the window ID, HUD-style translucency to a `SystemBackdrop`
  (`MicaBackdrop`/`DesktopAcrylicBackdrop`) rather than raw alpha, and the
  toolbar-button mask to `AppWindowTitleBar` button-visibility properties.

