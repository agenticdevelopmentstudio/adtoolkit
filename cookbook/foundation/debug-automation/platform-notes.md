
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/CoreMacOS/DebugAutomation/{DebugLaunchSwitch,NSApplication+QuietActivation,NSWindow+TestHostVisibility,QuietWindowPresentation}.swift`.
  Nothing here is SwiftUI-specific: `DebugLaunchSwitch` depends only on
  `Foundation`'s `UserDefaults`, and the other three files operate on plain
  `AppKit` `NSApplication`/`NSWindow` instances beneath any SwiftUI
  `WindowGroup`/`Window` scene that hosts them.
- **Compose**: There is no Android/Compose Desktop analogue to a launch
  argument read from an argument domain; the closest equivalent is a
  `BuildConfig.DEBUG`-gated check of an `am start --es` extra or a
  `SharedPreferences` Boolean. `isRunningInTests` would map to detecting
  `androidx.test.platform.app.InstrumentationRegistry` on the classpath.
  There is no per-window desktop-level compositing to sink a window behind
  on Android or Compose Desktop; a Compose Desktop port would instead have
  to withhold `Window`'s focus request / `alwaysOnTop` rather than move it
  behind a desktop-level constant, since AWT/Swing has no
  `CGWindowLevelForKey(.desktopWindow)` equivalent.
- **React/Web**: No analogue exists for either half. A browser page cannot
  read a native launch argument; the nearest equivalent is a
  `process.env.NODE_ENV !== 'production'` gate (build-time, like the
  debug/release split) combined with a URL query parameter or
  `localStorage` flag in place of the argument domain. There is also no
  desktop window level to sink behind — a browser tab does not share
  desktop z-order with other native applications the way a native window
  does, so an E2E harness (Playwright/Cypress) drives the page without the
  app needing to suppress its own foregrounding.
- **AppKit / UIKit**: This recipe is extracted directly from AppKit (the
  source platform). The debug launch switch is `DebugLaunchSwitch`
  (`DebugLaunchSwitch.swift`), a `Sendable`, `Hashable` `struct` with
  `key: String` as its only stored property; enabled-state reads are `isOn`
  / `isOn(defaults:)`, gated by `#if DEBUG` / `#else` compiler branches
  (release builds skip the `UserDefaults` read entirely). The launch
  argument is passed as `open -n -g -a <App> --args -<key> YES`, landing in
  `UserDefaults`'s argument domain, which `isOn(defaults:)` reads via
  `defaults.bool(forKey: key)`. The quiet presentation gate is the
  `@MainActor` enum `QuietWindowPresentation` (`QuietWindowPresentation.swift`):
  `debugSwitch = DebugLaunchSwitch("QuietWindowPresentation")`,
  `defaultsKey`, `isEnabled`, and `resolve(isTestHost:defaults:)`. Test-host
  detection is `NSWindow.isRunningInTests` (`NSWindow+TestHostVisibility.swift`),
  which checks `NSClassFromString("XCTestCase") != nil`. The conditional
  activation operation is `NSApplication.activateUnlessQuiet()`
  (`NSApplication+QuietActivation.swift`), calling
  `activate(ignoringOtherApps: true)` only when disabled. The three window
  operations — sink-behind-desktop, quiet order-front, and quiet
  make-key-and-order-front — are `NSWindow.sinkBehindDesktop()`,
  `orderFrontQuietly()`, and `makeKeyAndOrderFrontQuietly()`
  (`NSWindow+TestHostVisibility.swift`), which wrap `orderFront(nil)` /
  `makeKeyAndOrderFront(nil)` around setting
  `level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))`;
  `sinkBehindDesktop()` never calls `orderOut`, `close`, or touches
  `isVisible`/`alphaValue`. `orderFrontQuietly()` and
  `makeKeyAndOrderFrontQuietly()` are declared `@MainActor`;
  `sinkBehindDesktop()` and `isRunningInTests` carry no actor annotation of
  their own in this source file, though every call site in this recipe's
  own files reaches them only from an already-`@MainActor` caller. UIKit
  (iOS) has no multi-app desktop compositing or unfocused-app foregrounding
  concept in the same sense — an iOS app is always the single foreground
  app when running — so there is no sink-behind-desktop analogue; the
  nearest iOS equivalent of "quiet" automation would be skipping a scene's
  `UIWindowScene` activation request rather than moving a window's z-order.
- **WinUI 3**: Read the launch argument via
  `Environment.GetCommandLineArgs()` (or `AppInstance.GetActivatedEventArgs().Data`
  for a already-running-instance activation), gated by the C# `#if DEBUG`
  preprocessor directive exactly as `isOn(defaults:)` gates on Swift's
  `DEBUG`; store the flag under `ApplicationData.Current.LocalSettings.Values["QuietWindowPresentation"]`
  read only inside that `#if DEBUG` block, mirroring the
  `UserDefaults`-key/launch-argument coupling. Detect a test host by
  checking `AppDomain.CurrentDomain.GetAssemblies()` for
  `Microsoft.VisualStudio.TestPlatform` (or the MSTest/xUnit runner
  assembly) in place of `NSClassFromString("XCTestCase") != nil`. For the
  window-level trick, `AppWindow` exposes no direct
  "desktop window level" constant; the nearest equivalents are
  `AppWindow.MoveInZOrderAtBottom()` or a P/Invoke `SetWindowPos` call with
  `HWND_BOTTOM`, in place of setting `NSWindow.level`. For activation,
  WinUI 3's `AppWindow.Show(activateWindow: Boolean)` takes an explicit
  activate flag directly — a WinUI port can pass `activateWindow: false`
  in one call, rather than needing a separate `NSApplication.activate(ignoringOtherApps:)`
  gate the way `activateUnlessQuiet()` does.

