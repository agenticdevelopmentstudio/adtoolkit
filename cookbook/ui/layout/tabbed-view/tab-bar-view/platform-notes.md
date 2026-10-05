
- **SwiftUI**: Model the item list as an array of a lightweight identifiable
  struct plus an external `selectedID`, both owned by the caller (mirroring
  `items`/`selectedID` being handed in rather than owned). Render one edge's
  bar as an `HStack` (top/bottom) or `VStack` (left/right) of pill `Button`s,
  each with a `.background(RoundedRectangle(cornerRadius: 4).fill(...))` that
  swaps between the `.selection` and clear fills and a text-color swap between
  `.selectionText`/`.secondaryText`, matching `updateAppearance()`; overlay a
  trailing close `Button` sized `14×14` the way `closeButton` sits inside
  `backgroundView`, giving it its own tap target so a tap there does not also
  select (SwiftUI's default hit-testing already scopes a nested `Button`'s
  tap to itself, unlike the manual frame-containment check
  **close-icon-hit-routes-to-close** performs). There is no SwiftUI analog to
  `NSStackView.addSubview(_:positioned:relativeTo:)`; reproduce the
  vertical-edge overlap and depth ordering with `.offset`/`.zIndex` driven by
  each item's index distance from the selection, recomputed the way
  `applyStackOrder()` does.
- **Compose**: Keep the item list and `selectedId` in a `ViewModel`. Render a
  horizontal bar as a `Row` and a vertical bar as a `Column` of
  `Surface`/`FilterChip`-based pill composables, driving the same fill/text/
  icon-tint swap from `MaterialTheme`-derived colors; give each pill a
  trailing icon `IconButton` for close, sized to mirror the `14×14pt` hit
  area, and let Compose's own click-consumption on that inner control keep it
  from also triggering the pill's `Modifier.clickable` (no manual
  frame-containment test is needed, unlike the source's `mouseDown` check).
  Reproduce the `-16dp` vertical overlap and depth ordering with
  `Modifier.offset` and `zIndex()` computed from each item's index distance
  from the selected one.
- **React/Web**: Keep the tab array and `selectedId` in component state.
  Render a bar as a flex container (`flex-direction: row` for top/bottom,
  `column` for left/right), each tab a `<button>` toggling a selected/
  unselected class (background + text/icon color, matching
  `updateAppearance()`'s role swap) and containing a nested close `<button>`
  whose click handler calls `event.stopPropagation()` — the direct web analog
  of `TabButton.mouseDown`'s frame-containment check — so a close click never
  also selects. Reproduce the vertical overlap with a negative `margin-top`
  (mirroring `-16pt`) and a `z-index` computed from each item's index
  distance from the selected tab.
- **AppKit/UIKit** (source platform): Implemented entirely in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/MultiTabbedViewController/TabBarView.swift`
  as three types: `TabBarView` (an `NSView` hosting an `NSStackView`), the
  private `TabItemHostView` (click-to-select wrapper for a `.viewController`
  item's view), and the private `TabButton` (the `.title` item's pill,
  including its own `NSButton`-based close icon). This is macOS/AppKit-only —
  there is no UIKit code path in source. `TabBarView`, `TabItemHostView`, and
  `TabButton` each fatal-error if constructed through `init?(coder:)`
  (`rejects-coder-initializer`), and all three are `@MainActor`-isolated,
  usable only on the main actor (`confines-to-main-actor`) — which is what
  backs the single-thread confinement described under Edge Cases. A
  UIKit/iPadOS port would replace `NSStackView` with `UIStackView`,
  `closeButton`'s `.inline` `NSButton` bezel with a plain `UIButton`
  (`.image(systemName: "xmark.circle.fill")`), and the `mouseDown`-based
  frame-containment hit test with a `UITapGestureRecognizer` on the wrapper
  plus the close button's own `.touchUpInside`, ordered (or
  `cancelsTouchesInView`-configured) so the close button's own target fires
  instead of the wrapper's when both would otherwise match. Internally,
  `TabBarView` tracks its items through a private `NSStackView`, per-id
  `TabButton`/`TabItemHostView` dictionaries, a hosted-controller map, and a
  thickness constraint; the Behavioral Requirements above describe the
  resulting observable behavior rather than these private names directly, so
  a refactor that keeps the behavior intact does not break conformance.
- **WinUI 3** (the reason this recipe exists): No built-in WinUI 3 control is
  shaped like this — `TabView` supports only a single top-docked strip, not
  a per-edge bar with vertical overlap. Build the bar as a `StackPanel`
  (`Orientation="Horizontal"` for top/bottom, `"Vertical"` for left/right)
  hosting an `ItemsRepeater` (or `ListView` with its `ItemsPanel` swapped to
  a `StackPanel`), one `ToggleButton`-templated pill per tab: a `Border` with
  `CornerRadius="4"` (mirroring `backgroundView.layer.cornerRadius`) around a
  `TextBlock` bound to the tab title (`FontSize`/`FontWeight` from the
  theme's caption-equivalent resource, mirroring the `.caption` text role)
  and a small close `Button` templated to the Segoe Fluent Icons "Cancel"
  glyph (``), sized to `14×14` `Width`/`Height` to mirror `closeButton`'s
  fixed hit area. Drive the selected/unselected swap with a
  `VisualStateManager` `Selected`/`Unselected` state group that swaps
  `Background`/`Foreground` brush resources — matching
  `.selection`/`.selectionText` vs. transparent/`.secondaryText` — rather
  than `ToggleButton`'s own default checked brush, so one brush pair serves
  every tab. Apply `outerPadding`/`endPadding` as `Margin` on the strip's
  outer (window) edge and at its two length-wise ends only, leaving the
  workspace-side edge flush (mirroring `applyEdgeInsets()`). Reproduce the
  vertical bar's card overlap and depth ordering with a negative `Margin`
  (`-16`) between items plus `Canvas.ZIndex` recomputed from each item's
  index distance from the selected one, the same calculation
  `applyStackOrder()` performs, since `ItemsRepeater`/`StackPanel` has no
  native reordering-on-selection behavior. There is no WinUI analog to
  `mouseDown`'s point-in-`closeButton`-frame test: set `e.Handled = true` in
  the close `Button`'s own `Click`/`PointerPressed` handler so the event never
  bubbles up to fire the pill's own selection `Click`.

