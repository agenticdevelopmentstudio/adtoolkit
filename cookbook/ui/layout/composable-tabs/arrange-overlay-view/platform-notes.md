
- **SwiftUI**: Layer a `ZStack` of the pane's content behind a scrim colored
  by the consumer's semantic-palette lookup for `.windowBackground` at 0.72
  opacity (SwiftUI has no built-in `Color(role:)` initializer; this is the
  same lookup `SemanticPalette.nsColor(_:)` performs on the source platform),
  and center a `VStack(spacing: 10)` of the pane-name `Text` above an
  `HStack(spacing: 8)` toolbar (`RoundedRectangle(cornerRadius: 8)` background in
  `.elevatedSurface`, `.strokeBorder(.border, lineWidth: 1)`) of `Button`s
  and a `Menu` in place of the `NSPopUpButton`. Because SwiftUI gesture
  modifiers consume the touches they attach to rather than letting them
  bubble to an ancestor the way AppKit's default `mouseDown` forwarding
  does, achieving `scrim-click-still-reaches-pane-selection` needs the
  scrim's own tap handler to explicitly re-invoke the same "select this
  pane" closure the content view uses, rather than relying on any automatic
  propagation.
- **Compose**: Use a `Box` whose bottom layer is the pane's content and
  whose top layer is a `Modifier.background(...alpha = 0.72f)` scrim,
  centering a `Column` (pane-name `Text` plus a `Card`/`Surface` toolbar
  `Row` of `Button`s, each showing a leading `Icon` plus text `Text`
  (mirroring `toolbar-buttons-show-icon-and-label`), 8dp corner radius, 1dp
  border, elevatedSurface background) via `Modifier.align(Alignment.Center)`.
  Give the scrim's `Box` a `pointerInput` block that consumes events (mirroring
  `scrim-blocks-clicks-to-content`), and, since Compose has no equivalent of
  AppKit's automatic bubble-to-ancestor for an unhandled touch, wire that
  same `pointerInput` handler to call the pane's own "select" function
  directly (mirroring `scrim-click-still-reaches-pane-selection`).
- **React/Web**: An absolutely positioned `<div>` covering the pane's
  content, with `background: rgba(<windowBackground>, 0.72)`, containing a
  centered flex column (10px gap) of the pane name above a flex row (8px
  gap, 8px padding, 8px border-radius, 1px solid border, elevatedSurface
  background) of `<button>` elements. The scrim's default `pointer-events:
  auto` already gives `scrim-blocks-clicks-to-content` for free; leave the
  scrim's own `onClick` handler unset (or set to one that does not call
  `stopPropagation()`), so an unhandled click naturally bubbles up to the
  pane container's own click listener, giving
  `scrim-click-still-reaches-pane-selection` via the DOM's own
  event-bubbling to an ancestor listener — no explicit re-invocation of the
  "select this pane" handler is needed, unlike SwiftUI/Compose, where
  gesture modifiers consume the touch before it can propagate.
- **AppKit/UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsArrangeOverlayView.swift`
  as a `@MainActor`, `final` `NSView` built from `NSStackView`s and Auto
  Layout constraints, installed and removed as a subview by
  `ComposableTabsPaneViewController.installArrangeOverlay()`/
  `removeArrangeOverlay()` whenever `ComposableTabsArrangeMode` toggles for
  the window. Theming comes from `observeTheme(_:)`/`SemanticPalette`, and
  the four Move directions come from the shared `ComposableTabsMoveMenu`
  class, reused by the pane's own gear menu. It also does not support
  construction via a coder-based initializer — Cocoa's `NSCoder`-driven
  `init(coder:)` — which this type overrides to trigger a fatal error
  immediately, since no code path in this app constructs this overlay from
  an archived storyboard/xib. There is no UIKit code path in source (the
  imports — `AppKit`, `AgenticToolkitCore`, `AgenticToolkitCoreMacOS` — are
  macOS-only); a UIKit port would replace `NSButton`/`NSPopUpButton` with
  `UIButton`/`UIMenu`, replace the responder-chain click-through with an
  explicit `UITapGestureRecognizer` on the scrim that calls the pane-select
  handler directly (UIKit has no equivalent of AppKit's free
  unhandled-`mouseDown` forwarding), and would need each control's tappable
  area grown to at least 44×44pt.
- **WinUI 3** (the reason this recipe exists): Build the scrim as a
  dedicated `Border`/`Rectangle` filling the pane,
  `Background="{ThemeResource WindowBackgroundBrush}"` with `Opacity="0.72"`
  set on that element alone — not on a `Grid` that also hosts the toolbar,
  since WinUI's `Opacity` dims an entire subtree and would otherwise fade
  the toolbar too, unlike AppKit's layer-alpha, which only dims `self`'s own
  layer while the toolbar is a separate opaque sibling layer.
  `WindowBackgroundBrush`, `ElevatedSurfaceBrush`, and `BorderBrush` are not
  built-in WinUI 3 resources; they are app-defined theme resource keys the
  consumer supplies to mirror `SemanticPalette`'s roles. Stack a `TextBlock`
  (style `SubtitleTextBlockStyle`, matching the `.heading` text role) above a
  `Border` toolbar (`CornerRadius="8"`, `BorderThickness="1"`,
  `BorderBrush="{ThemeResource BorderBrush}"`,
  `Background="{ThemeResource ElevatedSurfaceBrush}"`) containing a
  horizontal `StackPanel` (`Spacing="8"`) of `Button`s with icon+text
  `Content` (mirroring `imagePosition = .imageLeading`), replacing the
  `NSPopUpButton` pull-down with a `DropDownButton` whose `Flyout` is a
  `MenuFlyout` built the same way `ComposableTabsMoveMenu.makeItems` is: one
  `MenuFlyoutItem` per `Direction.allCases`, each `IsEnabled` bound to
  whether `availableDirections()` contains it, each `Icon` a matching arrow
  `SymbolIcon`/`FontIcon`, and `Text` set to the movement name (Left, Right,
  Up, Down). WinUI's `Tapped`/`PointerPressed` are routed events that bubble
  automatically from the source element up through its visual-tree
  ancestors, invoking any ancestor's handler unless something upstream sets
  `e.Handled = true` — the opposite of the claim that they arrive
  pre-handled. `scrim-click-still-reaches-pane-selection` therefore falls out
  of that default bubbling as long as the pane's selection handler is
  attached to an ancestor of the scrim and nothing along the way marks the
  event handled; this is the mirror image of AppKit, where it is an
  *unhandled* `mouseDown` that walks the responder chain. Implementors should
  still confirm no intervening `Border`/`Grid` handler marks `e.Handled`,
  since that is the one way the click would fail to reach the pane's
  selection handler — call this out to implementors as a deliberate platform
  difference worth verifying rather than assuming. Bind `IsEnabled` on the
  Add/Remove `Button`s to `canAdd`/`canRemove` the same way
  `refreshAvailability()` re-reads them, and leave the Done `Button` with no
  `AccessKey` bound, mirroring `done-button-has-no-key-equivalent`.
- **UI-thread confinement**: `confines-to-ui-thread` — the view is declared `@MainActor`, so use from off the main actor fails to compile.

