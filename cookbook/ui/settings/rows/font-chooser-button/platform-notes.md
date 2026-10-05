
- **SwiftUI**: There is no first-party SwiftUI API on macOS for presenting
  the system font panel. Wrap the same `NSFontManager`/`NSFontPanel`
  machinery behind an `NSViewRepresentable` (or an `NSViewController`-based
  representable) whose `Coordinator` conforms to `NSFontChanging`, mirroring
  `changeFont(_:)` and `validModesForFontPanel(_:)` exactly as this source
  does; expose the drawn font/title through `@Binding`s and forward panel
  picks through the coordinator the same way `onChange` does here.
- **Compose**: Android provides no system font panel or font-family
  picker; build a `Button` whose label is drawn with the currently selected
  `FontFamily` at a fixed sample size (mirroring `sampleSize`), and open a
  custom `AlertDialog`/`ModalBottomSheet` listing the app's own bundled
  font families and sizes on click (mirroring `openFontPanel`'s role),
  forwarding the picked family/size back through a callback (mirroring
  `onChange`) with no attempt at persistence of its own.
- **React/Web**: The web has no built-in font panel either. Compose a
  `<button>` whose `style.fontFamily` reflects the current selection at a
  fixed sample `font-size`, opening a custom popover/dialog listing
  available fonts (the CSS Font Loading API's `document.fonts`, or a
  fixed app-defined list) on click; forward the picked family/size through
  a callback prop, mirroring `onChange`, with the parent responsible for
  any persistence.
- **AppKit / UIKit (source)**: Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/FontChooserButton.swift`.
  A macOS-only (`import AppKit`) `NSButton` subclass, `@MainActor`, nested
  inside the `ComposableSettings` namespace, conforming to
  `NSFontChanging`. On construction it also sets
  `translatesAutoresizingMaskIntoConstraints = false` (the mechanism behind
  **fixed-width-constraint** and **no-width-constraint** being expressible
  as Auto Layout constraints at all) and sets `NSFontManager.shared.target`
  to itself when opening the panel (the mechanism behind
  **font-change-forwarding** receiving picks at all). There is no UIKit
  code path in source. A UIKit port would present
  `UIFontPickerViewController` (a full-screen modal list, not a floating
  always-on-top panel like `NSFontPanel`) and receive the pick through
  `UIFontPickerViewControllerDelegate`, rather than through the
  target-managed `NSFontManager`/`NSFontChanging` pairing this file uses;
  the target-release workaround in
  **releases-picker-registration-on-removal** has no UIKit equivalent to
  port, since a presented view controller is dismissed rather than leaked
  at a shared singleton. `NSFontManager.target` is declared
  `unowned(unsafe)` (per the source's own test suite comment), so a button
  deallocated together with its entire window — rather than first removed
  from it — can leave the manager writing into freed memory;
  `viewDidMoveToWindow()`'s target-release only fires on individual window
  removal, not on `deinit` (see Design Decisions for the accepted residual
  risk).
- **WinUI 3**: WinUI 3 ships no system-wide font panel window analogous to
  `NSFontPanel`. Build a `Button` whose `Content` is a `TextBlock` bound to
  the current font's display name, with the `TextBlock`'s `FontFamily`
  bound to the selected font and its `FontSize` fixed to a sample size
  constant (mirroring `sampleSize`, e.g. `12`), regardless of the font's
  own configured size — mirroring #requirements/sample-size. Wire `Click`
  to open a custom `ContentDialog` or `Flyout` hosting a
  `ListView`/`ComboBox` enumerating installed font families (via
  `Microsoft.UI.Xaml.Media.FontFamily` / `DWriteCore` font enumeration) and
  a `NumberBox`/`Slider` for point size, since there is no system dialog to
  defer to. Track "who currently owns the open font-choosing UI" explicitly
  in the dialog/flyout's own lifecycle (its `Closed` event), since WinUI
  has no shared, app-wide singleton target to release the way
  `viewDidMoveToWindow` releases `NSFontManager.shared.target` — mirroring
  **releases-picker-registration-on-removal**'s intent without its
  mechanism.
  On the dialog's confirm/selection-changed event, invoke a caller-supplied
  callback (mirroring `onChange`) with the chosen `FontFamily` and size,
  and let the caller call an equivalent of `show(fontFamily:title:)` back
  on the button afterward to update its own displayed sample and title —
  mirroring the source's "stores nothing itself" design. `Button`'s default
  `VisualStateManager` groups (`Normal`, `PointerOver`, `Pressed`,
  `Disabled`) already cover pressed/disabled visuals without custom state
  XAML, matching the source's own lack of custom pressed/disabled styling.

