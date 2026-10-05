
- **SwiftUI**: Model each edge's tab list as an `@State`/`@Observable` array
  keyed by a stable id, and the active tab as a single shared id (or a
  `groupID`, to reproduce cross-edge sibling selection). Render each enabled
  edge's bar as an `HStack`/`VStack` (chosen by `Edge.isVertical`) of pill
  buttons inside a `ScrollView`, each with a `.background` capsule that swaps
  fill/foreground on selection the way `TabButton.updateAppearance()` does,
  and a trailing close `Button`. Compose the four bars and the center content
  with nested `VStack`/`HStack`s mirroring `rebuildEdgeConstraints()`'s
  top/bottom-row, left/right-column arrangement, hiding a disabled edge's bar
  with `if isEdgeEnabled(edge) { ... }` rather than an `isHidden` flag. There
  is no first-class SwiftUI analog for the vertical-edge card overlap/z-order
  behavior; reproduce it with `.offset`/`.zIndex` driven by each item's index
  distance from the selection.
- **Compose**: Mirror the same per-edge tab list and shared active-id/group-id
  state in a `ViewModel`. Render a horizontal edge with a `Row` of
  `FilterChip`/custom `Surface` pills inside a horizontally-scrolling
  container, and a vertical edge with a `Column` of the same, using
  `Modifier.offset`/`graphicsLayer { translationY = ... }` and `zIndex()` keyed
  on each item's distance from the selected index to reproduce the `-16pt`
  overlap and depth ordering. Compose a `Scaffold`-style frame with `Row`/
  `Column` slots for the up-to-four bars around the content, showing or hiding
  a bar's Composable entirely (not just visually) to mirror `isHidden`.
- **React/Web**: Represent each edge's tabs as an array in component state,
  keyed by id, with a shared `activeGroupId`. Render a top/bottom edge as a
  `<div>` with `display: flex; flex-direction: row` and a left/right edge with
  `flex-direction: column`, each tab a `<button>` styled with the selected/
  unselected background and text-color swap; a `position: relative` wrapper
  with negative `margin` (mirroring the `-16pt` overlap) and `z-index`
  computed from index-distance-from-selection reproduces the vertical card
  stack. Compose the up-to-four bars and the center `<div>` with CSS Grid
  (`grid-template-areas` for top/left/center/right/bottom), toggling a bar's
  `display: none` to mirror `isHidden`.
- **AppKit / UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/MultiTabbedViewController/`
  across `MultiTabbedViewController.swift` (edge/tab/selection state, layout,
  center mounting), `TabBarView.swift` (bar rendering, `TabButton`,
  `TabItemHostView`, card stacking), `TabItem.swift` (`TabItem`,
  `TabBarHostedItem`, `TabBarStackedItem`), `Edge.swift`, and
  `MultiTabbedViewControllerDelegate.swift`. This is a macOS-only, AppKit
  `NSViewController` component with no UIKit code path in source.
  `loadView()`, `viewDidLoad()`, and `preferredContentSizeDidChange(for:)`
  are declared `open` so a subclass can extend them (`open-for-subclassing`,
  folded in here because it is purely a Swift subclassing detail, not a
  behavior of the concept itself). `MultiTabbedViewController`, `Tab`'s
  storage (`EdgeState`), and `TabBarView` are all `@MainActor`-isolated,
  which is what backs the single-thread confinement described under Edge
  Cases. `contentInsets` is an `NSEdgeInsets` applied as layout-constraint
  constants, with the trailing and bottom insets given as negative constants
  (inward) and the top and leading insets as positive constants. `TabButton`
  sets `accessibilityRole = .button` and `setAccessibilityElement(true)`,
  which stops AppKit from hoisting its subviews into the tree in its place;
  nothing in `MultiTabbedViewController.swift` or `TabBarView.swift` posts an
  `NSAccessibility.post(element:notification:)` call for a programmatic
  active-tab change, and neither `TabButton` nor `TabItemHostView` implements
  `acceptsFirstResponder`/`keyDown`/key-view-loop wiring, so a tab is
  reachable only by a pointer click or an existing VoiceOver cursor's
  `accessibilityPerformPress()`. The close icon is the `xmark.circle.fill` SF
  Symbol. Padding constants are named `TabBarView.outerPadding` (6pt),
  `endPadding` (8pt), `itemSpacing` (4pt), and `cardOverlap` (-16pt); the tab
  button's corner radius is `backgroundView.layer?.cornerRadius` and the
  content area's border is `centerContainer.layer?.borderWidth`. Reusing one
  view controller across two tabs is not guarded by `addTab`/`insertTab`;
  AppKit's own view-controller containment is the only thing that reacts to a
  violation. A UIKit/iPadOS port has no direct analog to four independently
  toggleable, sibling-linked edge bars around one content area; it would most
  likely be a hand-built container using `UIStackView`s for each edge
  (mirroring this file's own `NSStackView`-per-edge structure) and a custom
  container view controller for the center, rather than `UITabBarController`,
  which supports only one bottom bar and no cross-edge group selection.
  Internally (private, not part of the conformance contract above — cited
  here rather than in the test vectors): `tabBars: [Edge: TabBarView]` holds
  each edge's bar view; `centerContainer` is the shared content wrapper and
  `mountedCenterController` tracks the controller currently mounted in it;
  each bar keeps its thickness in `thicknessConstraint` and lays items out in
  an `NSStackView` (`stack`) whose `edgeInsets` hold the per-side padding;
  `TabButton` draws selection through `backgroundView.layer` and a
  `titleLabel` role swap.
- **WinUI 3**: There is no single WinUI 3
  control that docks tab bars on all four sides with cross-edge sibling
  selection, so build the frame as a `Grid` with `Auto`-sized
  `RowDefinition`s/`ColumnDefinition`s for the top/bottom/left/right bar slots
  around a `Star`-sized center `ContentPresenter`, collapsing a disabled
  edge's row/column to `0` (`Visibility="Collapsed"` on that bar) to mirror
  `isHidden`/`rebuildEdgeConstraints()`. WinUI 3's native `TabView` only
  supports a single top-docked strip and has no notion of a tab linked across
  several instances, so represent each edge's bar as a `ListView` (or
  `ItemsRepeater`) of `ToggleButton`-based pill items inside a horizontal or
  vertical `StackPanel`/`ItemsStackPanel` (chosen by `Edge.isVertical`),
  driving each item's checked visual state with a `VisualStateManager`
  `Selected`/`Unselected` state group that swaps `Background`/`Foreground`
  brushes the way `TabButton.updateAppearance()` swaps palette roles. Persist
  a `groupID`-style key alongside each `ListView`'s items and, on any one
  edge's `SelectionChanged`, programmatically set the matching item selected
  on every other edge's `ListView` to reproduce
  `group-siblings-share-selection-across-edges`. Bind each bar's
  `MinWidth`/`MinHeight` (top/bottom vs. left/right) to the hosted content's
  measured `DesiredSize` plus `6epx`, clamped to the `28epx`/`140epx` floor, to
  mirror `tab-bar-thickness-floor-and-growth`. Reproduce the vertical-edge
  card overlap with a negative `Margin` on each item plus `Canvas.ZIndex` set
  from each item's index-distance from the selected one, mirroring
  `applyStackOrder()`; a close glyph can use the Segoe Fluent Icons
  `` ("Cancel") glyph sized to match the `14×14pt` hit area.
- **UI-thread confinement**: `confines-to-ui-thread` — the view controller is declared `@MainActor`, so use from off the main actor fails to compile.

