
- **SwiftUI**: Compose an `HStack` with `Text(viewModel.title)` and a
  trailing font-sample button (an `NSViewRepresentable` wrapping
  `FontChooserButton`, per `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`'s
  own SwiftUI note, or an equivalent custom `Button` that opens a font
  picker) bound to a `Binding` that reads and writes through the same
  view-model font, mirroring **commits-picked-font-through-view-model** and
  **observes-external-view-model-changes**; drive both the label's opacity
  and the button's `disabled(_:)` from one `isEnabled` boolean, mirroring
  **dims-and-disables-the-row**.
- **Compose**: Use a `Row` with a leading `Text(title)` and a trailing
  sample `Button` whose label is drawn in the currently selected
  `FontFamily` at a fixed sample size, opening a custom
  `AlertDialog`/`ModalBottomSheet` listing available font families and
  sizes on click (there is no Android system font panel to defer to, per
  `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`'s Compose note); commit the
  picked family/size back to the view model unconditionally on selection,
  and gate both children's `enabled`/alpha from one boolean, mirroring
  **dims-and-disables-the-row**.
- **React/Web**: A flex row (`display: flex; align-items: center`)
  containing a `<span>` for the title and a trailing `<button>` styled with
  `style.fontFamily` set to the current selection at a fixed sample
  `font-size`, opening a custom popover/dialog listing available fonts (the
  CSS Font Loading API's `document.fonts`, or a fixed app-defined list) on
  click; forward the picked family/size through a callback prop mirroring
  **commits-picked-font-through-view-model**, and toggle a `disabled`
  attribute plus a reduced-opacity class on both children together,
  mirroring **dims-and-disables-the-row**.
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/FontPickerView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, inside the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`. It
  composes two subviews - a `ThemedLabel` from
  `ComposableSettings.makeRowLabel` and a `FontChooserButton` - into one row
  via `ComposableSettings.makeRow` and `pinToEdges`. `button`'s title text is
  computed by a private static `describe(_:installed:)` helper, which formats
  `"<name> — <size> pt"` and appends `" (not installed)"` when the font is
  not installed - see **describes-font-name-and-rounded-point-size** and
  **flags-an-uninstalled-font-in-its-title**. `init?(coder:)` and
  `init(frame:)` are both overridden to call `fatalError` (the mechanism
  behind **requires-view-model-at-construction**), leaving the designated
  `init(viewModel:)` as the only surviving construction path. There is no
  UIKit code path in source; a UIKit port has no `NSFontPanel` equivalent to defer to
  (see `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`'s own AppKit/UIKit
  note for the button's side of that gap) and would need its own
  `isEnabled`-driven dimming, since UIKit has no direct `alphaValue`
  analogue on `UILabel` beyond its inherited `UIView.alpha`.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `Auto,*`: a `TextBlock` bound to `viewModel.title`
  in column 0, and in column 1 the font-sample `Button` described in
  `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`'s own WinUI 3 note (its
  `Content` `TextBlock` bound to the selected font's family/size at a fixed
  sample `FontSize`, opening a `ContentDialog`/`Flyout` for selection since
  WinUI ships no system font panel). Wire that dialog's confirm/selection
  event to call an equivalent of `viewModel.setFont` unconditionally on
  every pick, then re-read the view model's current font/title back into
  both the `TextBlock` and the sample `Button` - mirroring
  **commits-picked-font-through-view-model** and
  **resyncs-synchronously-after-a-pick** in one step, since WinUI has no
  separate `UserSettingObserver` Combine hop to produce a second,
  asynchronous re-sync the way this source's `sizeObserver`/`nameObserver`
  do (see Edge Cases, "Repeated sync after a single font pick" - a WinUI
  port that binds both the `TextBlock` and the sample `Button`'s content to
  the same `INotifyPropertyChanged` font property gets the same
  eventually-consistent redraw without needing to replicate the double
  callback). Drive both children's `Opacity`/`IsEnabled` from one bound
  boolean to mirror **dims-and-disables-the-row**'s all-or-nothing row
  dimming, and append a not-installed qualifier to the `TextBlock`'s bound
  display string (via an `IValueConverter`) mirroring
  **flags-an-uninstalled-font-in-its-title**.

