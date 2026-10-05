
- **SwiftUI**: There is no view-controller-returning factory pattern in
  SwiftUI; model the registry as a small `@MainActor` class holding
  `[ComposableTabsViewID: (ComposableTabsViewDescriptor, (ComposableTabsViewContext) -> AnyView)]`
  and expose it via `.environmentObject` or an `@Environment` key, so a pane
  host resolves content with `registry.makeContent(for:context:)` returning
  `AnyView` instead of a view controller. The placeholder becomes a plain
  `View`: a `ZStack` with a `.background(color.opacity(0.15))` modifier and a
  centered `Text("Pane \(paneNumber)")` with its font resolved from the
  environment's theme — `.font(theme.font(for: .heading))`, read via an
  `@Environment` theme key — never a hardcoded `.font(.title)`, so it stays
  the SwiftUI analogue of the source's theme-token-only `.heading` role;
  retinting happens automatically when the environment's theme value changes
  rather than through an explicit `observeTheme` call.
- **Compose**: Hold the registry as a plain Kotlin class mapping a view id to
  a descriptor plus a `@Composable (ComposableTabsViewContext) -> Unit`
  factory (Compose has no view-controller-owning-child concept, so a
  composable function fills the factory's role directly). The placeholder
  becomes a `Box(Modifier.fillMaxSize().background(seriesColor.copy(alpha = 0.15f)))`
  with a centered `Text("Pane $paneNumber", style = MaterialTheme.typography.headlineSmall)`;
  teardown moves from an adopted protocol to a `DisposableEffect`'s `onDispose`
  block on the pane's composable, and confirmation-before-removal becomes a
  plain nullable-string-returning function called before dismissal.
- **React/Web**: Model the registry as a plain object or `Map` from a string
  view id to `{ descriptor, factory }`, where `factory` is a component
  constructor or render function (a component registry / plugin-map pattern,
  common in extensible web apps). The placeholder becomes a functional
  component rendering a `div` sized by its flex/grid pane, with
  `backgroundColor` set to the series color at 15% alpha via CSS
  `color-mix()` or an rgba string, and a centered `<span>Pane {n}</span>`
  styled from the app's heading token; teardown maps to a `useEffect` cleanup
  function in place of `PaneContentTeardown`, and removal confirmation to a
  plain callback prop returning a string or `undefined`.
- **AppKit/UIKit**: This is the source platform; see
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsViewRegistry.swift`.
  It is macOS/AppKit-only: the registry (`ComposableTabsViewRegistry`), the
  context (`ComposableTabsViewContext`), and the placeholder
  (`PlaceholderPaneViewController`) are all `@MainActor`-isolated, which is
  the reason there is no defined cross-thread behavior in Edge Cases. The
  `Factory` typealias returns `NSViewController`; `NSColor`, and
  `NSLayoutConstraint.Priority` (whose `.defaultLow.rawValue + 10` is the
  concrete arithmetic behind **fractioned-priority-boost**) have no UIKit
  equivalent as written. `PlaceholderPaneViewController.init(coder:)` is
  marked unavailable and traps with a fatal error if ever invoked — a
  construction-time compiler/runtime rule of the platform, not an
  independently testable behavior of the registry (`coder-init-unavailable`
  in prior revisions of this recipe). The placeholder's container is a
  plain `NSView` with `wantsLayer = true`; its tint is set on
  `CALayer.backgroundColor` from `palette.chartSeriesNSColors[(paneNumber - 1) % series.count]`;
  its title is a `ThemedLabel` with `textRole: .heading` and
  `role: .primaryText`, so its font and color come from
  `SemanticPalette.font(.heading)` and `palette.nsColor(.primaryText)`, and
  retinting is driven by an `observeTheme` closure rather than a
  declarative environment binding. Logging uses `Loggable`, deriving its
  subsystem from `Bundle.main.bundleIdentifier` and its category from the
  conforming type's name (`ComposableTabsViewRegistry`), and logs through
  `Self.logger.error(...)` with the view id's `rawValue` interpolated at
  `privacy: .public`. A UIKit port would change `Factory` to return
  `UIViewController`, swap `NSColor` for `UIColor` and
  `NSLayoutConstraint.Priority` for `UILayoutPriority`, and would need its
  own container-view-controller embedding (`addChild`/`didMove(toParent:)`)
  in place of whatever AppKit-specific embedding the pane view controller
  performs outside this file.
- **WinUI 3**: Model
  `ComposableTabsViewRegistry` as a C# class holding a
  `Dictionary<string, (ComposableTabsViewDescriptor Descriptor, Func<ComposableTabsViewContext, UserControl> Factory)>`
  (the `Factory` typealias becomes a `Func<...>` returning a `UserControl` or
  `Page`, since WinUI panes host XAML content rather than a
  `NSViewController`); `Register`, `Unregister` (refusing the placeholder key
  exactly as `placeholder-protection` requires), `RegisteredViewIds`
  (sorted with `OrderBy(id => id, StringComparer.Ordinal)`), `IsRegistered`,
  `Descriptor`, and `MakeContentView` mirror the six public members 1:1.
  `ComposableTabsViewDescriptor` becomes a C# record with `DisplayName`,
  `IconSource` (a `SymbolIconSource`/`FontIconSource` in place of an SF Symbol
  name), `PreferredAxis`, `MinimumThickness` (bound to a `GridSplitter`
  pane's `MinWidth`/`MinHeight`), `PreferredThicknessFraction` (mapped to a
  `GridLength` star value on the hosting `Grid.ColumnDefinitions`/`RowDefinitions`),
  `IsCollapsible`, and `HoldingPriority`; XAML's `Grid` has no holding-priority
  construct comparable to Auto Layout's, so `ResolvedHoldingPriority` has no
  direct WinUI analogue — the nearest equivalent is choosing which column gets
  a fixed `GridLength` versus a `*`-weighted one, which is a layout-time
  decision rather than a runtime priority value, and is the one part of this
  recipe with no 1:1 WinUI mapping. The placeholder becomes a `UserControl`
  with a `Border` whose `Background` is a `SolidColorBrush` built from the
  theme's chart-series brush resource at 15% `Opacity` (mirroring
  `withAlphaComponent(0.15)`), containing a `TextBlock`
  `HorizontalAlignment="Center" VerticalAlignment="Center"` bound via
  `x:Bind PaneNumber` and styled `Style="{StaticResource TitleTextBlockStyle}"`
  (the Fluent 2 analogue of the `.heading` `TextRole`); since the control has
  no interactive states, no `VisualStateGroup` beyond the default
  `CommonStates.Normal` is needed. Retinting on theme change replaces the
  source's `observeTheme` associated-object mechanism with `{ThemeResource}`
  brush bindings plus a handler on the app's own theme-store change event —
  the `observeTheme` analogue — rather than
  `FrameworkElement.ActualThemeChanged`, which only fires when the system
  switches between light and dark and would miss an in-app `SemanticPalette`
  theme change. Logging replaces `Loggable`/`OSLog` with
  `Microsoft.Extensions.Logging.ILogger<ComposableTabsViewRegistry>`, using
  the same category-equals-type-name convention.
- **UI-thread confinement**: `confines-to-ui-thread` — the registry, its descriptor context and the placeholder pane are declared `@MainActor`, so use from off the main actor fails to compile.

