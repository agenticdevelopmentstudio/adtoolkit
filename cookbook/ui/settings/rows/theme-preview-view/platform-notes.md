
- **SwiftUI**: Compose a `VStack(spacing: 10)` of five card `View`s (each a
  `RoundedRectangle(cornerRadius: 8).fill(...)` background with a `VStack`
  of its own content, `.frame(minWidth: 280, maxWidth: .infinity)`) followed
  by a swatch grid (`LazyVGrid`), all reading colors and fonts from an
  `@Environment` or `@ObservedObject` wrapping the same `SemanticPalette`
  role API this source uses, so a theme change recomposes every sample the
  same way `show(_:)` rebuilds it.
- **Compose**: A `Column` of `Card` composables (`Modifier.fillMaxWidth()`,
  `Modifier.widthIn(min = 280.dp)`, `shape = RoundedCornerShape(8.dp)`,
  `backgroundColor` bound to the theme role), each containing a `Column`/`Row`
  of `Text`/`Box` elements styled from `MaterialTheme.colors`/`typography`
  mapped from the same semantic roles, plus a `LazyVerticalGrid` for the
  ANSI swatches (see the `SwatchGridView` recipe's own Compose note).
- **React/Web**: A flex column of five `<div class="card">` blocks (
  `border-radius: 8px`, `min-width: 280px`, `width: 100%`, background from a
  `--surface`/`--window-background` custom property) each laid out with
  `padding: 10px 12px`, followed by a CSS Grid of ANSI swatches (`gap` and
  `grid-template-columns: repeat(8, ...)`, mirroring the `SwatchGridView`
  recipe). Because the preview must show the given `theme` prop rather than
  whichever theme is currently active app-wide, every custom property is set
  inline on the preview's own root element (`style={{ '--surface':
  theme.surface, ... }}`) from that prop, not read from the document-level
  theme class/attribute the rest of the app uses — so passing a different
  `theme` repaints only the preview, exactly as the show operation does
  imperatively here.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/ThemePreviewView.swift`.
  A macOS-only (`import AppKit`), `@MainActor` `NSView` subclass in the
  `ComposableSettings` namespace, conforming to `SettingsViewProtocol`. The
  component is constructed only via `init(theme:)`; the fatal-erroring
  `init?(coder:)` traps at runtime, so a caller cannot construct one
  through that path. It composes a single vertical `NSStackView` of five
  hand-built card views (each an `NSView` with a `CALayer` background,
  built from nested `NSStackView`s of `NSTextField(labelWithString:)`
  labels and plain layer-backed `NSView`s for pills/badges/rows/the caret)
  plus one embedded `ComposableSettings.SwatchGridView`. There is no UIKit
  code path in source; a UIKit port has no direct `NSStackView`-of-cards
  equivalent and would instead compose a vertical `UIStackView` of card
  `UIView`s (each `layer.cornerRadius`/`backgroundColor` styled the same
  way), with `UILabel`s in place of `NSTextField(labelWithString:)` and the
  same `SwatchGridView`-equivalent grid embedded at the end. Implementation
  detail: `container` is pinned to `self` via the shared `Self.pinToEdges`
  helper; each card's content stack is built by the private
  `fill(_:with:)` helper; and `show(_:)` tears down the prior cards with
  `container.arrangedSubviews.forEach { $0.removeFromSuperview() }` before
  rebuilding.
- **WinUI 3**: Compose a vertical `StackPanel` (`Spacing="10"`) of five
  `Border` "card" elements (`CornerRadius="8"`, `MinWidth="280"`,
  `HorizontalAlignment="Stretch"`), each containing a `StackPanel` of
  `TextBlock`/`Border` children styled per the requirements above (a "pill" is
  a `Border` with `CornerRadius="5"` around a `TextBlock`; a status badge is
  the same shape with its `Background`/`BorderBrush` bound through a converter
  to the status color at 22%/55% opacity). Because the preview must render the
  `ColorTheme` it is given rather than the app's currently active theme, every
  `Background`/`Foreground`/`BorderBrush` binds to a `ResourceDictionary` built
  at preview-construction time from that `ColorTheme` and merged only into the
  preview's own subtree (for example via `FrameworkElement.Resources` on the
  container) — never to the app-wide `{ThemeResource}` brushes (such as
  `CardBackgroundFillColorDefaultBrush`) that repaint with whichever theme is
  currently active. Terminal padding maps to the `Border`'s `Padding` property
  bound directly to the four resolved padding values; the caret maps to a
  small `Border`/`Rectangle` whose `Width`/`Height`/`CornerRadius`/
  fill-vs-outline are chosen from a `VisualStateManager` group with one state
  per cursor-shape case (Block/HollowBlock/Underline/Bar), each setter
  matching the width/height math in `cursor-shape`. The ANSI swatch grid
  maps to an `ItemsRepeater` with a `UniformGridLayout`, exactly as in the
  `SwatchGridView` recipe's own WinUI 3 note. Rebuilding that scoped
  `ResourceDictionary` from a new `ColorTheme` (WinUI's analogue of calling
  the show operation with a new theme) repaints the whole preview without
  touching the app's own active theme resources.

