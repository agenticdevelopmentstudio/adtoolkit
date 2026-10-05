
- **SwiftUI**: The source is entirely AppKit
  (`packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectChooserWindow.swift`):
  `NSWindowController`, `NSWindowDelegate`, `NSWindow`, and a private
  `NSViewController`. A SwiftUI port has no built-in app-modal API on
  macOS — `.sheet` requires a presenting window this app cannot guarantee
  exists (per the source's own doc comment) — so a SwiftUI rewrite would
  still need an `NSWindow`/`NSApp.runModal` bridge (or an `NSHostingController`
  wrapped exactly as this file wraps its AppKit content view controller)
  rather than a pure `WindowGroup`/`Scene`. The window is constructed with a
  fixed style mask (`[.titled, .closable, .resizable]`), buffered backing,
  and no deferred creation; `init?(coder:)` is unavailable and calls
  `fatalError` if invoked, for both the window controller and its private
  content view controller, so neither can be instantiated from a storyboard
  or nib. Both types are declared `@MainActor` and declare no `Sendable`
  conformance, so every stored property (`content`, `chosen`, `onFinish`,
  `browser`, `openButton`) and every method of both is confined to the main
  actor by that declaration alone, not by any lock either type defines
  itself.
- **Compose**: There is no macOS-style "app-modal window with no guaranteed
  parent" concept in Compose; the closest model is a second top-level
  `Window` (or `DialogWindow`) shown independently of any owner, with the
  "wait for a choice" contract expressed as a `CompletableDeferred<GitRepo?>`
  that the caller awaits while the window is visible, completed by the
  Open/Cancel composables and by the window's own close handler — mirroring
  **content-onfinish-drives-outcome** and
  **window-close-ends-session-as-cancel**.
- **React/Web**: A browser has no native modal window or app-modal concept;
  port the chooser as a modal dialog component (a `<dialog>` element or a
  focus-trapping overlay) with Escape and Enter key handlers standing in for
  the Cancel/Open key equivalents, and express `choose(from:onChoose:)`'s
  callback contract as a `Promise<GitRepo | null>` the caller awaits instead.
- **AppKit / UIKit**: The source already is AppKit. iOS has no
  app-modal-window concept at all (an iOS app has one window); the closest
  UIKit port is a modally presented `UIViewController` (`.overFullScreen` or
  a form sheet) with a Cancel bar button and a Done/Open bar button whose
  `isEnabled` mirrors **open-button-enablement-tracks-selection** — there is
  no Escape-key or Return-key hardware default to carry over. Cancel and
  Open are built as stock `NSButton` instances with `bezelStyle: .push`.
  Quiet presentation is checked through `NSApp.activateUnlessQuiet()`
  (`CoreMacOS/DebugAutomation/NSApplication+QuietActivation.swift`), which
  calls `NSApplication.activate(ignoringOtherApps: true)` unless
  `QuietWindowPresentation.isEnabled` is `true`.
- **WinUI 3**: Port `ProjectChooserWindow` as a secondary
  `Microsoft.UI.Xaml.Window`, not a `ContentDialog` — a `ContentDialog`
  requires an already-visible owner `XamlRoot`, the same "no guaranteed
  parent" problem the source's doc comment raises about `NSPanel` sheets.
  Because WinUI 3 has no `NSApp.runModal` equivalent, express the "wait for
  a choice" contract with a `TaskCompletionSource<GitRepo?>` that button
  click handlers and the window's `Closed` event complete exactly once
  (`TrySetResult`, mirroring **onchoose-single-invocation** and
  **window-close-ends-session-as-cancel**), and have a `ChooseAsync` method
  `await` that source the way `choose(from:onChoose:)` awaits `runModal()`.
  Set the window's initial `AppWindow.Resize` to 460×480 and its minimum
  size to 360×300 (handled in `AppWindow.Changed`/`WindowSizeChanged`, since
  `AppWindow` has no direct `MinSize` property), and title it `"Open
  Project"`. Build the button pair as two `Button` controls in a horizontal
  `StackPanel`; set `IsDefault="True"` on the Open button to mirror the
  Return key-equivalent's default-button tint, and give Cancel a
  `KeyboardAccelerator` with `Key="Escape"` to mirror its Escape
  key-equivalent. Bind the Open button's `IsEnabled` to the hosted list's
  selection-changed event exactly as **open-button-enablement-tracks-selection**
  requires. There is no `NSApp.modalWindow`-identity concept to check in
  `Closed`, so mirror
  **window-close-ignored-when-not-active-modal-session**'s one-shot
  guarantee with `TaskCompletionSource.TrySetResult(null)`, which is a no-op
  once a button click has already completed the source. Set
  `AutomationProperties.AutomationId` on the window, the Cancel button, and
  the Open button to mirror **accessibility-identifiers-fixed**.

