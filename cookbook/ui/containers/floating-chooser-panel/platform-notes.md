
- **SwiftUI**: not the source form. SwiftUI's `WindowGroup`/`Scene` APIs
  have no equivalent to an on-demand, pointer-positioned, `.floating`-level
  panel that joins all Spaces, so a SwiftUI-first chooser would still wrap
  its view in an `NSHostingController` and host it inside an `NSPanel`
  managed by a controller shaped like this one, rather than a pure `Scene`.
- **Compose (Desktop)**: the nearest equivalent is an undecorated
  `androidx.compose.ui.window.Window` (`undecorated = true`,
  `alwaysOnTop = true` for floating-level behavior), positioned
  programmatically on each show; Compose for Desktop has no built-in
  equivalent to `.collectionBehavior`'s space-joining or to automatic
  dismissal on focus loss, so both would need direct AWT/Swing interop on
  top of the `Window` composable.
- **React/Web**: the nearest equivalent is a fixed-position, non-modal
  overlay (a portal styled with `position: fixed`), centered horizontally
  and offset from the top by a percentage of the viewport height; dismissal
  on focus loss has no browser-window analog for an in-page element, so it
  would be approximated with an outside-pointerdown listener and an
  `Escape` keydown handler instead of `windowDidResignKey`.
- **AppKit / UIKit**: this is the source platform, and it is AppKit-only —
  no UIKit counterpart exists (iOS has no floating, multi-Space panel
  concept). File: `FloatingChooserPanelController.swift`. It also calls
  `NSApplication.activateUnlessQuiet()`, defined in
  `NSApplication+QuietActivation.swift`. Concrete API mapping for the
  requirements above: the class is `open`, `@MainActor`, and an
  `NSWindowController` subclass; it fails with a fatal error if constructed
  via `init?(coder:)` (`rejects-coder-initialization`), since it provides
  no Interface Builder/`NSCoding` support. The container/content
  relationship is `NSViewController`s, with the container set as
  `window.contentViewController` and the hosted content added as a
  child controller; the content view's edges are pinned with Auto Layout
  (`translatesAutoresizingMaskIntoConstraints = false`). The window is an
  `NSPanel` with `styleMask == [.titled, .closable, .fullSizeContentView]`;
  `titleVisibility == .hidden` and `titlebarAppearsTransparent == true`;
  `standardWindowButton(_:)` for `.closeButton`, `.miniaturizeButton`, and
  `.zoomButton` each have `isHidden == true`; `window.level == .floating`;
  `collectionBehavior` includes `.canJoinAllSpaces` and
  `.fullScreenAuxiliary`; `styleMask` omits `.resizable`;
  `isReleasedWhenClosed == false`. Positioning uses
  `NSEvent.mouseLocation` to find the pointer's screen, falls back to
  `NSScreen.main`, and falls back further to `NSWindow.center()` when
  `visibleFrame` is unavailable; the horizontal formula is
  `origin.x = visibleFrame.midX - width / 2`, and the vertical offset is
  driven by the fixed constant `topInsetFraction = 0.2`. Activation and
  showing go through `NSApp.activateUnlessQuiet()` (which skips
  `activate(ignoringOtherApps:)` when `QuietWindowPresentation.isEnabled`
  is `true`), then `showWindow(nil)`, then
  `window.makeKeyAndOrderFront(nil)`, then the overridable
  `takeInitialFocus()` hook. Dismissal flows through `windowDidResignKey`
  calling `close()` (guarded by the `dismissesOnFocusLoss`,
  `isDismissing`, and window-visibility checks above), `close()` itself
  guarding reentrancy against `super.close()` and clearing `isDismissing`
  after it returns, and `windowWillClose` calling the overridable
  `panelWillClose()` hook exactly once. The initializer signature is
  `init(content: NSViewController, contentRect: NSRect)`.
- **WinUI 3**: the closest native shape is a secondary, undecorated
  `Microsoft.UI.Xaml.Window`/`AppWindow` with
  `TitleBar.ExtendsContentIntoTitleBar = true` (the WinUI analog of
  `fullSizeContentView`) and `IsShownInSwitchers = false`. There is no
  direct WinUI equivalent to `.floating` window level or to hiding just the
  close button of a titled window the way `standardWindowButton(_:).isHidden`
  does here — an `OverlappedPresenter` with `IsAlwaysOnTop = true` covers the
  always-on-top intent, but a truly buttonless-yet-framed title bar needs a
  fully custom `AppWindowTitleBar` (via `SetPreferredResizableRegions` /
  `ExtendsContentIntoTitleBar`) rather than hiding individual buttons.
  `.canJoinAllSpaces` has no WinUI counterpart either; Windows virtual
  desktops are a separate `VirtualDesktopManager` API and would need
  explicit pin-to-all-desktops calls to match. Positioning maps to
  `DisplayArea.GetFromWindowId`'s work area: center horizontally, offset the
  top edge by 20% of the work-area height, then call `AppWindow.Move`.
  Dismissal on focus loss maps to the `Window.Activated` event with
  `WindowActivationState.Deactivated`, checked against a
  `DismissesOnFocusLoss`-equivalent property before closing — with the same
  reentrancy guard this base class keeps as an owned boolean, since WinUI
  activation events have the same "state hasn't finished updating yet"
  hazard this file's `isDismissing` comment describes.
- **UI-thread confinement**: `confines-to-ui-thread` — the class is declared `@MainActor` and is an `NSWindowController` subclass, so construction or use from off the main actor fails to compile.

