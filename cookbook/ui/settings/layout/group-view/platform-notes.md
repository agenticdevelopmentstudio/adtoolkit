
- **SwiftUI**: Use `Section` with a leading, `.caption`-styled header text
  above a `VStack` clipped to a `RoundedRectangle` (matching the 10pt
  `cardCornerRadius`) and filled with the elevated-surface color, mirroring
  `#requirements/card-surface`; insert `Divider()` between rows only where
  the source's own `#requirements/separator-visibility` rule would show one
  — SwiftUI's `Section` in a `List`/`Form` already renders this pattern
  close to natively on macOS/iOS, so a from-scratch `VStack` is only needed
  for a fully custom card. Give a `.continuation`-styled child no top
  padding and no `Divider()` above it, mirroring
  `#requirements/continuation-padding`. Drive a row's presence with
  structural conditional inclusion (`if !isHidden { row }`) rather than
  `.hidden()`, the same substitution the sibling
  `ConditionalView`/`DismissibleHintView` recipes make, so a hidden row's
  divider and padding close up the way `#requirements/row-visibility-
  binding` does here.
- **Compose**: Build a `Column` with a `.caption`-styled `Text` above a
  `Card`/`Surface` (`shape = RoundedCornerShape(10.dp)`,
  `colors = CardDefaults.cardColors(containerColor = <elevated-surface
  token>)`), and lay rows out in an inner `Column` inserting a thin
  `HorizontalDivider` between consecutive visible rows only — computed the
  same way the source walks its rows, tracking whether a not-hidden,
  non-continuation predecessor has been seen (see
  `#requirements/separator-visibility`). Apply `Modifier.padding` per row
  matching the 9dp/14dp vertical/horizontal insets, and `0.dp` top padding
  for a continuation row.
- **React/Web**: Render a `<fieldset>` or `<section role="group"
  aria-labelledby="...">` whose caption is a `<legend>`/heading with
  `id="..."` matching `aria-labelledby` — the explicit label association
  that the source's AppKit implementation never establishes (see Label
  requirements) — inside a `div` styled with `border-radius: 10px` and the
  elevated-surface background token. Give each `.row` child
  `padding: 9px 14px` and a `border-top: 1px solid var(--divider)` on every
  child except the first visible one, mirroring
  `#requirements/separator-visibility` / `#requirements/first-row-headless`;
  give a `.continuation` child `padding-top: 0` and no `border-top`. Toggle
  a row's presence with conditional rendering (removing the node), not
  `display: none` alone, so the surrounding gap actually closes, mirroring
  `#requirements/row-visibility-binding`.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/GroupView.swift`,
  with layout constants from `ViewLayout.swift` (`SettingsLayout.default`,
  keyed `.cardCornerRadius` = 10pt, `.captionSpacing` = 6pt,
  `.cardHorizontalInset` = 14pt, `.cardVerticalInset` = 9pt,
  `.dividerThickness` = 1pt — the source of every fixed number in this
  recipe), `ThemedBox`/`ThemedSeparatorView`/`ThemedLabel` from the
  `agenticdevelopertoolkit` submodule's `ThemedViews.swift` (`card-surface`
  is a `ThemedBox` filled with `.elevatedSurface`, `stroke: nil`), and the
  caption view from `HeaderView.swift`. A macOS-only (`import AppKit`)
  `NSView` subclass, `@MainActor`, inside the `ComposableSettings`
  namespace, built entirely on `NSStackView` and Auto Layout. The rows live
  in a private `rowStack`, each wrapped in a private `CardRow` tracked in a
  private `rows` array; a row's divider is a private `line`/
  `separatorHeight` pair, and `showsSeparator`'s `didSet` short-circuits on
  an unchanged `oldValue` to skip redundant writes — the requirements above
  describe these mechanics only by their observable effect, since any of
  these names could change under a refactor without changing what the card
  looks like or does. `confines-to-ui-thread` is enforced at compile time
  by the class's `@MainActor` declaration: the Swift compiler rejects
  construction or mutation of a `GroupView` from a non-isolated context.
  `translatesAutoresizingMaskIntoConstraints` is set to `false` on the view
  itself, `outerStack`, `rowStack`, the header view, and `cardView` — an
  Auto Layout construction rule with no portable analog, required only so
  the constraint-based requirements above (`outer-stack-edge-pinning`,
  `header-width-match`, `card-width-match`, `row-area-edge-pinning`, and the
  rest) can take effect at all. Neither `GroupView` nor its row type
  supports construction via a decoding-based (`init?(coder:)`) initializer:
  both call `fatalError` instead of returning a usable instance, so no code
  path returns a decoded instance for either type. There is no UIKit code
  path in source; a UIKit port would replace `NSStackView` with
  `UIStackView`, `NSView.isHidden` with `UIView.isHidden` (the same
  removal-from-layout semantics apply within a `UIStackView`), and would
  have no `NSCoder`-only initializer restriction to fatal-error on the way
  the decoding-rejection behavior above does here.
- **WinUI 3** (the reason this recipe exists): Compose the group from a
  `TextBlock` caption (`Style="{StaticResource CaptionTextBlockStyle}"`)
  positioned above a rounded `Border` (`CornerRadius="10"`, matching
  `cardCornerRadius`, `Background="{ThemeResource
  CardBackgroundFillColorDefaultBrush}"`, `BorderThickness="0"`, matching
  `#requirements/card-surface`'s `stroke: nil`) containing a vertical
  `StackPanel` of row `Border`s. Reproduce `#requirements/separator-
  visibility` / `#requirements/first-row-headless` with a value converter,
  keyed on item index and visibility, that suppresses a row's top `Border`
  divider (`BorderThickness="0,1,0,0"`, `BorderBrush="{ThemeResource
  DividerStrokeColorDefaultBrush}"`) unless a prior, still-visible,
  non-continuation row exists. Bind each row `Border`'s own `Visibility` —
  not just its inner content's — to the wrapped content's visibility, since
  a `StackPanel` does not auto-collapse a row's own padding around a
  `Visibility="Collapsed"` child's slot the way an `NSStackView` collapses a
  hidden arranged `NSView`; this is the direct analog of
  `#requirements/row-visibility-binding` and is required for the
  divider-recompute analog above to see accurate "still-visible" state.
  Give each row `Padding="14,9,14,9"` (a continuation row
  `Padding="14,0,14,9"`), matching `#requirements/row-content-padding` /
  `#requirements/continuation-padding`.

