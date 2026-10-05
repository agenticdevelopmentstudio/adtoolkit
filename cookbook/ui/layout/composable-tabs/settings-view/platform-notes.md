
- **SwiftUI**: Rebuild the sheet as a `NavigationSplitView` (sidebar +
  detail) inside a `.sheet`, with a `List` of two `NavigationLink`-backed
  rows ("Tabs", "Spacing") in the sidebar. The Tabs panel becomes a
  `VStack` of four `Toggle` rows bound to a view model wrapping
  `isEdgeEnabled`/`setEdgeEnabled`; re-read the authoritative value from the
  view model inside the `Toggle`'s binding setter, after calling
  `setEdgeEnabled`, to mirror reverts-checkbox-to-authoritative-state (a
  plain `Binding` would otherwise trust the tap). The Spacing panel becomes
  two grouped `Stepper`/`TextField` pairs bound to `AppStorage` (SwiftUI's
  analog of the app-wide integer settings). Use
  `.toolbar { ToolbarItem { Button("Done") { dismiss() } } }` with
  `.keyboardShortcut(.defaultAction)` for the Return-bound Done button.
- **Compose**: Use a two-pane `Row` (`NavigationRail` or a simple `Row` with
  a fixed-width sidebar `Column`, matching the non-draggable sidebar) with a
  `Column` of `Checkbox` rows for Tabs and two `OutlinedTextField`/stepper
  groups for Spacing, persisted through `DataStore` (the Compose/Android
  analog of the app-wide integer settings). Re-read the source of truth
  after each `onCheckedChange` call before updating the `Checkbox`'s
  displayed `checked` state, mirroring reverts-checkbox-to-authoritative-state.
  Use `Modifier.focusRequester`/`FocusManager.moveFocus` to stitch the same
  closed Tab loop between the two spacing groups.
- **React/Web**: A two-column layout (`display: grid;
  grid-template-columns: auto 1fr`) with a `<nav>` list of two buttons
  ("Tabs", "Spacing") and a content pane holding four `<input
  type="checkbox">` rows for Tabs and two grouped `<input type="number">` +
  stepper pairs for Spacing, persisted via `localStorage` (the web analog of
  the app-wide integer settings). After each toggle's `onChange`, re-read
  the authoritative value from the store and reset `checked` from it rather
  than trusting the event, mirroring reverts-checkbox-to-authoritative-state.
  Use explicit `tabIndex` values (or DOM order) to close the Tab loop
  between the last field of one spacing group and the first field of the
  other.
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsSettingsViewController.swift`.
  A macOS-only (`import AppKit`), `@MainActor` composition of one public
  `NSViewController` (`ComposableTabsSettingsViewController`) and three
  private classes: the topic list is the private
  `ProjectSettingsSplitViewController`, subclassing
  `ComposableSettings.SplitViewController` and added as a child view
  controller via `addChild`; the Tabs and Spacing panels are private
  `ComposableSettings.SettingsPanelViewController` subclasses
  (`ProjectTabsSettingsPanel`, `ProjectSpacingSettingsPanel`). All four
  classes are `final`, and all four mark `init(coder:)`
  `@available(*, unavailable)` to produce a fatal-error trap if invoked
  (`rejects-coder-initialization`/`rejects-coder-initialization-on-panels`
  in prior revisions of this recipe; this is a construction-time
  compiler/runtime rule of the platform, not an independently testable
  behavior of the component). The Done button is rendered with
  `bezelStyle = .rounded`; its activation shortcut is set via
  `keyEquivalent = "\r"`. This component composes
  `ComposableSettings.SplitViewController`, `SettingsPanelViewController`,
  `GroupView`, `HelpPopoverController`, and `SpacingControl` — all defined
  elsewhere in `AgenticToolkit` — rather than reimplementing any of their
  layout or persistence logic. The Tabs panel's icon is the SF Symbol
  `rectangle.3.group`; the Spacing panel's icon is `squareshape.split.2x2`.
  The frame-spacing control is constructed via
  `SpacingControl.boundToSettings(style: .frame, edges: PaneSpacing.edgeSettings)`,
  and the divider-spacing control via
  `SpacingControl.boundToSettings(style: .paneDividers, gutters: PaneSpacing.gutterSettings)`.
  The closed Tab loop is wired via `nextKeyView`. There is no UIKit code
  path in source; a UIKit port would need an entirely different navigation
  shell, since `NSSplitViewController`'s sidebar/detail model has no direct
  `UISplitViewController` equivalent at this content-sized-sidebar,
  non-draggable configuration.
- **WinUI 3** (the reason this recipe exists): Build the sheet as a
  `ContentDialog` (overriding the `ContentDialogMaxWidth` resource, since
  its default caps a dialog at roughly 548 effective pixels wide — well
  under the 760pt this sheet needs) or, more simply, a secondary `Window`
  sized 760×520 effective pixels, matching the preferred content size,
  hosting a `NavigationView` with
  `PaneDisplayMode="Left"`, `IsPaneOpen="True"`, and `IsSettingsVisible="False"`
  — `NavigationView`'s pane, unlike `SplitView`'s, has no user-draggable
  splitter by default, which is the WinUI analog of the fixed sidebar
  width. Populate it with two `NavigationViewItem`s ("Tabs",
  icon `Segoe Fluent Icons` glyph for a grid/tab-row shape; "Spacing", a
  layout-grid glyph), selecting the first on load
  (`SelectedItem = navView.MenuItems[0]`) to mirror selecting the Tabs
  panel by default. The Tabs content is a `StackPanel` of four
  `CheckBox` controls (`Content="Top"`, `"Right"`, `"Bottom"`, `"Left"`)
  whose `Checked`/`Unchecked` handlers call the injected setter and then
  explicitly set `IsChecked` back from the injected getter's current value
  — WinUI's two-way `x:Bind` would otherwise leave the box showing whatever
  the user clicked, so the handler-level re-read is required to reproduce
  reverts-checkbox-to-authoritative-state. Guard that re-read (a boolean
  flag, or comparing against the value already set) before writing
  `IsChecked`, since setting it from inside the `Checked`/`Unchecked`
  handler re-fires that same handler; alternatively, handle `Click` instead
  of `Checked`/`Unchecked` to sidestep the re-entrancy entirely. Set
  `AutomationProperties.Name` on each `CheckBox` from its content text
  (the WinUI analog of the visible label supplying the accessible name),
  and additionally mark the `CheckBox` with
  `AutomationProperties.LiveSetting="Assertive"` (or raise a
  `FrameworkElementAutomationPeer` structure-changed event) when the
  handler corrects a refused uncheck — UI Automation does not re-announce a
  value the app itself just wrote back, which is the same gap this recipe
  flags in Accessibility. The Spacing content is two `Grid`s, each with a
  `NumberBox` (built-in spin buttons, `SpinButtonPlacementMode="Inline"`)
  per side/gutter, bound `Value="{x:Bind ..., Mode=TwoWay}"` to properties
  backed by `ApplicationData.Current.LocalSettings` (the WinUI/UWP analog
  of the app-wide integer settings); give each `NumberBox` a `Minimum="0"`
  and `Maximum="40"` to mirror the `0...40` default range. Stitch the same
  closed Tab loop between the two `NumberBox` groups with explicit
  `TabIndex` values (or `XYFocusUp`/`XYFocusDown` on the boundary
  controls), since `NumberBox`es placed in separate `Grid`s otherwise tab
  in visual, not intended, order. Present help from a `Button` with a
  `Flyout` (WinUI's analog of the popover-based help presenter), since a
  `ContentDialog` has no free window edge for a docked help drawer either.
- **UI-thread confinement**: `confines-to-ui-thread` — the view controller and its helper views are declared `@MainActor`, so use from off the main actor fails to compile.

