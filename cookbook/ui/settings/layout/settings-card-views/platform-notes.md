
- **SwiftUI (source)**: `SettingsCardViews.swift` is macOS-only SwiftUI,
  built entirely from stock view modifiers (`VStack`, `.background`,
  `.clipShape`, `.padding`, `.frame`) plus one `NSViewRepresentable`
  (`SettingsSearchField`) bridging AppKit's `NSSearchField`. Every metric
  it draws with comes from the same `ComposableSettings.SettingsLayout.default`
  subscript the AppKit `GroupView`/`CardRow` pair reads, which is what
  keeps a SwiftUI-authored panel on the same grid as an AppKit-authored
  one. `SettingsGroup` renders its caption via `Text(title)` styled `.caption`
  with the `secondaryText` color; because `title` is a `String` value
  rather than a `LocalizedStringKey` literal, it resolves through `Text`'s
  un-localized initializer (**group-title-not-auto-localized**), and
  `SettingsSearchField`'s `placeholder` likewise reaches
  `ThemedSearchField.placeholderString` verbatim
  (**search-field-placeholder-not-auto-localized**). `SettingsCard` clips
  with `RoundedRectangle(cornerRadius: 10, style: .continuous)`.
  `SettingsSearchField`'s `NSViewRepresentable.Coordinator` re-captures the
  current `text` binding on every `updateNSView` call, so the field's
  action always writes through the binding the current SwiftUI body
  captured rather than a stale one from an earlier render — a mechanic of
  bridging a native `NSSearchField` into SwiftUI's declarative re-render
  model, with no equivalent needed on a platform with no such bridge.
  `sizeThatFits` reports `nsView.fittingSize.height` as its height and the
  proposed width when one is offered, falling back to
  `nsView.fittingSize.width` otherwise. `SettingsCard` and
  `SettingsSearchField` are declared with no access modifier (internal),
  restricting their use to code inside the defining module — a Swift
  access-control choice with no runtime behavior of its own (see Design
  Decisions).
- **Compose**: Build the card with a Material 3 `Surface` (`shape =
  RoundedCornerShape(10.dp)`, `color = MaterialTheme.colorScheme.surfaceContainerHigh`
  or an equivalent elevated-surface token, `tonalElevation` for the raised
  look) holding a `Column` of rows, each an inset `Row`/`Box` with
  `Modifier.padding(horizontal = 14.dp, vertical = 9.dp)`; use
  `HorizontalDivider(modifier = Modifier.padding(start = 14.dp))` for the
  hairline, matching the leading-only inset. For the search field,
  Material 3's `SearchBar`/`DockedSearchBar` composable is the closest
  native equivalent — it already provides live `onQueryChange` callbacks
  and built-in accessibility, mirroring what wrapping a real native search
  control buys over a hand-rolled text field.
- **React/Web**: A `<section>` for the group with a labelled `<span>`
  caption above it — matching the source, which gives its caption no
  heading trait (see Accessibility) — a `<div>`
  styled `border-radius: 10px` and a background CSS custom property for
  the card, `padding: 9px 14px` per row, and a 1px `<hr>`/bordered `<div>`
  inset `margin-left: 14px` for the divider. Use `<input type="search">`
  for the search field — its native type gives Escape-to-clear and a
  search accessibility role in supporting browsers, the same argument
  used here for wrapping a genuine native search control instead of a
  bare `<input type="text">`.
- **AppKit / UIKit**: The AppKit translation of this exact vocabulary
  already exists elsewhere in this cookbook as the group view (caption +
  card), the themed box (the card's fill and corner radius), the private
  card row (row insets and separator), the themed separator view (the
  hairline), and the themed search field (the search field) — this
  SwiftUI vocabulary exists specifically to mirror them. A UIKit port
  with no AppKit sibling to mirror would use `UIStackView` for
  composition, a `UIView` with `layer.cornerRadius = 10` and
  `layer.cornerCurve = .continuous` for the card (matching this
  vocabulary's continuous curve, unlike the AppKit sibling's default
  circular curve — see Design Decisions), and `UISearchTextField`/`UISearchBar`
  in place of `NSSearchField` for the live-filtering field. `SettingsCard`
  and `SettingsSearchField`'s internal-only visibility
  (**card-stays-internal**/**search-field-stays-internal**, moved out of
  normative here) is a Swift access-control decision with no UIKit-side
  behavioral consequence beyond restricting which module can reference the
  type by name.
- **WinUI 3**: Build the card as a `Border` with `CornerRadius="10"` and
  `Background` bound to a brush equivalent to the elevated-surface role
  (Fluent 2's `CardBackgroundFillColorDefaultBrush` is the closest stock
  token), containing a `StackPanel` of rows; give each row a
  `Grid`/`StackPanel` with `Padding="14,9,14,9"` to match the
  card-horizontal/vertical insets, and separate rows with a 1px-tall
  `Rectangle` (or a `MenuFlyoutSeparator`-style `Border`) whose
  `Margin="14,0,0,0"` reproduces the leading-only inset and whose `Fill`
  binds to a divider-equivalent brush. Put the caption above the `Border`
  as a `TextBlock` styled `Style="{StaticResource CaptionTextBlockStyle}"`
  (or a custom style matching the port's 11pt caption size) with
  `Margin="0,0,0,6"` for the caption-to-card gap, and foreground bound to
  a secondary-text brush (`TextFillColorSecondaryBrush` is Fluent 2's
  stock equivalent). For the live-filtering search field, use
  `AutoSuggestBox` with its `TextChanged` event (fires per keystroke, the
  WinUI analog of sending the search action immediately) rather than
  waiting for a submit action — or a plain `TextBox` with a
  magnifying-glass `FontIcon` prefix if `AutoSuggestBox`'s suggestion
  popup is not wanted. Apply the panel-level inset with `Padding="20"` on
  the panel's root container.
- **confines-to-ui-thread**: On Apple platforms the type is `@MainActor`-isolated, so the compiler enforces the rule.

