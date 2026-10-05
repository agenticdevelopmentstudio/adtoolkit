
- **SwiftUI**: No SwiftUI in the source. SwiftUI's `.defaultPosition`,
  `.defaultSize` and scene restoration persist frames per scene but not per
  screen set; a SwiftUI port keeps this `@MainActor` class and reaches the
  underlying `NSWindow` (via an `NSViewRepresentable` window accessor) to
  call `restoreFrame` and `saveFrame`. `FrameCalculator` ports unchanged as
  pure functions on `CGRect`.
- **Compose**: Compose Desktop's `WindowState` (`position`, `size`) is the
  starting point, with `GraphicsEnvironment.getScreenDevices()` and
  `GraphicsConfiguration.bounds` / `Toolkit.getScreenInsets` for visible
  frames; persist with DataStore plus `kotlinx.serialization`, run on
  `Dispatchers.Main`. AWT coordinates are top-left-origin, so the top-left
  offset needs no y flip. Android phones have no free-floating windows; the
  math applies only to desktop and freeform modes.
- **React/Web**: Browsers expose window placement only for popups
  (`window.open` features, `moveTo` / `resizeTo`) and the Window Management
  API (`getScreenDetails()` with `availLeft` / `availTop` / `availWidth` /
  `availHeight`); persist with `localStorage` and `JSON.stringify`. No
  display UUID exists, so screen matching falls back to label and geometry;
  the pure frame math ports directly to TypeScript.
- **AppKit / UIKit**: Source files: `WindowFrameManager.swift`
  (`NSWindow.setFrame(_:display:animate:)`, `identifier`, `minSize`,
  `os.Logger` via `Loggable`), `FrameCalculator.swift` (pure `NSRect` math,
  bottom-left origin converted to top-left user coordinates),
  `PersistedWindowState.swift` (custom `Codable` with v1 fallback),
  `ScreenFingerprint.swift` (`CGDisplayCreateUUIDFromDisplayID` from
  `NSScreenNumber`), `ScreenInfo.swift`, `RealScreenProvider.swift`
  (`NSScreen.screens` / `NSScreen.main`), `ScreenMatcher.swift`,
  `WindowPosition.swift`. UIKit has no movable windows on iPhone; on iPad
  and visionOS use `UIWindowScene` geometry requests instead.
- **WinUI 3**: Start from `Microsoft.UI.Windowing.AppWindow` (`Position`,
  `Size`, `Move`, `Resize`, `MoveAndResize`, and the `Changed` event with
  `DidPositionChange` / `DidSizeChange` in place of the move/resize delegate
  hooks) and `DisplayArea.GetFromWindowId` / `DisplayArea.FindAll()`
  (`WorkArea` for the visible frame, `OuterBounds` for the resolution,
  `DisplayId` for identity). Windows coordinates are top-left-origin in
  physical pixels, so `topLeftOffset` needs no y flip but must account for
  DPI scaling (`XamlRoot.RasterizationScale`). Enforce `minSize` with
  `OverlappedPresenter` plus `PreferredMinimumWidth` /
  `PreferredMinimumHeight`. Keep the manager on the UI thread
  (`DispatcherQueue`), model `PersistedWindowState` as C# records serialised
  with `System.Text.Json` (a custom `JsonConverter` for the v1 fallback),
  and store them in `Windows.Storage.ApplicationData.Current.LocalSettings`
  (8 KB per value; use a `LocalFolder` file if many sets accumulate).
  Subscribe to display changes through `WM_DISPLAYCHANGE` /
  `WM_SETTINGCHANGE` or the `ScreenManager` port's event, and use
  `Task`/`async` only for file-based storage since the source is
  synchronous.

