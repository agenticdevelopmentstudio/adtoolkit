
- **SwiftUI**: There is no `NSHostingView` bridging concern to solve — a
  SwiftUI settings panel is itself a `View`. Model the base class as a
  protocol (e.g. `SettingsPanel: Identifiable, View`) with associated
  `descriptor` (title/icon/isDisabled/section, mirroring
  `SettingsPanelDescriptor`'s published fields as `@Published` on an
  `ObservableObject` or as plain properties on a `struct`), plus
  `helpContent`/`effectiveHelpContent`/`searchKeywords` given default
  implementations in a protocol extension — Swift's normal protocol-witness
  dispatch resolves these correctly for a `View`-conforming type, so the
  redeclare-for-dispatch workaround this file needs for an `any
  ComposableSettingsPanel` existential does not apply. Compose panel
  content from a `ScrollView { LazyVStack { ... } }` unless the panel
  declares it hosts its own scrolling, mirroring `hostsOwnScroll`.
- **Compose**: Define an interface (e.g. `SettingsPanel`) exposing a
  `descriptor` data class (`title: String`, `icon: Painter?`,
  `isDisabled: Boolean`, `section: String?`), a `@Composable fun Content()`,
  and `helpContent`/`effectiveHelpContent`/`searchKeywords` with default
  (empty/null) implementations via a Kotlin interface default method or an
  abstract base class. The hosting `NavigationDrawer`/two-pane `Scaffold`
  wraps `Content()` in a `Column(Modifier.verticalScroll(rememberScrollState()))`
  unless the panel's `hostsOwnScroll` is `true`, mirroring
  `SplitViewController`'s `PanelScrollView`-wrapping branch.
- **React/Web**: Define a component contract (a TypeScript interface or an
  abstract base class) with a `descriptor` object (`title`, `icon`,
  `isDisabled`, `section`) and a `render()`/functional component for
  content, plus `helpContent`/`effectiveHelpContent`/`searchKeywords`
  defaulting to `null`/`null`/`[]`. The hosting layout wraps rendered
  content in a `<div style="overflow-y: auto">` unless the panel opts out
  via a `hostsOwnScroll` flag, mirroring the `PanelScrollView` wrap/no-wrap
  branch. There is no direct analog to `hostingView(for:)`'s min/max-size
  workaround, since a React component never carries AppKit-style required
  size constraints into its parent.
- **AppKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/SettingsPanel/SettingsPanelViewController.swift`.
  A macOS-only (`import AppKit`, `import SwiftUI`), `@MainActor`, `open`
  `NSViewController` subclass conforming to `ComposableSettingsPanel`. The
  class declaration itself is the platform's contract: `@MainActor`
  confines every construction, read, and mutation of the class to the
  main actor under Swift's concurrency checking, and the class supports
  construction only through `init(with:)` — the required `init?(coder:)`
  is overridden to trigger a fatal error, so a caller cannot construct one
  through that path. It composes `PanelView`, `SettingsPanelDescriptor`,
  and `GroupView` — all defined elsewhere in `AgenticToolkit` — rather than
  reimplementing their layout. Its `loadView()` sets `self.view` to
  `settingsView`, the `PanelView` instance the class owns. The hosting
  helper's `NSHostingView` also sets
  `translatesAutoresizingMaskIntoConstraints = false`, opting the returned
  view out of AppKit's legacy autoresizing-mask-to-constraints translation
  so the Auto Layout constraints the caller applies are the only sizing
  authority. There is no UIKit code path anywhere in source;
  `ComposableSettings` is a macOS-only settings-window abstraction, so a
  UIKit port would need an entirely different navigation shell (e.g.
  `UISplitViewController`), not a line-for-line translation of this file.
- **WinUI 3**: Build the base class as an abstract `Page` (or
  `UserControl`), e.g. `SettingsPanelBase : Page`.
  - Descriptor: Expose a `Descriptor` object implementing
    `INotifyPropertyChanged` with `Title` (`string`), `Icon` (`IconSource?`),
    `IsDisabled` (`bool`, default `false`), and `Section` (`string?`) — the
    direct analog of `SettingsPanelDescriptor`'s `@Published` fields —
    constructed in the base class's constructor from an optional parameter,
    defaulting to a descriptor with an empty `Title` exactly as
    `init(with:)` does.
  - Virtual defaults: Give `HelpContent` (nullable), `EffectiveHelpContent`
    (defaulting to `HelpContent`), `HostsOwnScroll` (`bool`, default
    `false`), and `SearchKeywords` (`IReadOnlyList<string>`, default empty)
    each a `virtual` property with the base implementation supplying these
    defaults — WinUI's ordinary virtual-member dispatch through a base class
    reaches an overriding subclass correctly on its own, so the explicit
    redeclare-for-dispatch pattern this file needs (to defeat Swift's
    protocol-extension-default binding through an `any
    ComposableSettingsPanel` existential) has no WinUI counterpart to
    reproduce.
  - Scroll wrapping: The hosting `NavigationView`'s content presenter reads
    `HostsOwnScroll` to decide whether to wrap the panel's `Content` in a
    `ScrollViewer VerticalScrollBarVisibility="Auto"` or host it directly,
    mirroring `SplitViewController.show(_:)`'s `PanelScrollView`-wrapping
    branch.
  - Hosting-size analog: For the `hostingView(for:)` analog — hosting a
    differently-sized UI surface (a `WebView2`, or a control tree built by a
    different framework) inside a panel without letting its desired size
    drive the containing `Window`'s or `ContentDialog`'s size — note that
    WinUI 3's `Window` and `ContentDialog` have no `SizeToContent` property
    (that is a WPF API, not a WinUI 3 one). Instead, size the containing
    `Window` explicitly through `AppWindow.Resize` and give the hosted
    control `HorizontalAlignment="Stretch"` with `VerticalAlignment="Top"`
    inside a `ScrollViewer`, rather than letting the hosted control's
    `DesiredSize` drive the window's size. This reproduces `sizingOptions =
    [.intrinsicContentSize]`'s effect: the hosted content's size becomes a
    layout preference inside a `ScrollViewer`, never a hard constraint the
    containing window must satisfy.

