
- **SwiftUI**: `MCPChipsBar` and `MCPServerPicker` are already SwiftUI; a
  fully SwiftUI rebuild would drop the outer `NSView`/`NSHostingView` shell
  and host `MCPChipsBar` directly wherever the chat window's own view tree
  needs it, applying `.themedRoot()` once at that call site exactly as this
  file does. Keep `theme.font(.caption)`/`.heading` and `theme.accent`/
  `.secondaryText` unchanged, and keep reapplying `.themedRoot()` inside the
  `.popover` content — the source comment's "a popover is its own window"
  reasoning holds regardless of whether the presenting view is itself
  AppKit-hosted, because this app injects its custom `\.theme` environment
  value per hosting root rather than once at a single top-level SwiftUI
  `App` scene.
- **Compose**: Render the bar as a `Row` with an `Icon` (Material's closest
  server-rack glyph, or a custom vector asset) and a borderless `TextButton`
  showing the same three-branch label text, opening a `DropdownMenu`
  anchored to the button. List one `Row(Checkbox(checked = isActive(id)) {
  Text(name) })` per sorted server id inside the menu — Compose's ambient
  `MaterialTheme`/`CompositionLocal`s flow into a `DropdownMenu` without
  needing a manual reapply step, unlike `themedRoot()` here. Since each row
  has no fixed height in source, give the `TextButton` and each menu `Row` a
  minimum touch target of 48×48dp, matching Android's platform minimum (see
  **Minimum tap target** under Accessibility).
- **React/Web**: Render the bar as a flex row with an icon and a button
  (`aria-haspopup="true"`, `aria-expanded={showingPicker}`) that opens a
  popover component anchored below it (e.g. a Radix/Headless UI popover),
  listing one `<label><input type="checkbox" checked={isActive(id)} />
  {name}</label>` row per sorted server id, computed with the same
  three-branch label logic. If the popover implementation renders into a
  portal outside the bar's DOM subtree, verify CSS custom properties/theme
  context still reach it — the web analog of the `themedRoot()`-inside-the-
  popover quirk this source works around.
- **AppKit / UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/Features/AIChatWindow/MCPChipsBarView.swift`.
  A `@MainActor`, `final` `NSView` that hosts SwiftUI content
  (`MCPChipsBar`/`MCPServerPicker`) via `NSHostingView`, pinned to its own
  bounds with Auto Layout, rather than being built as raw AppKit controls.
  Both the host view and its hosted subview set
  `translatesAutoresizingMaskIntoConstraints = false` and rely on Auto
  Layout constraints, pinned to the parent's edges, for
  **fills-parent-bounds** rather than autoresizing masks. The host view does
  not implement `init(coder:)` — a storyboard/xib instantiation attempt
  traps with a fatal error, since this view is only ever constructed
  programmatically. The rack icon is the SF Symbol `"server.rack"`; the
  disclosure chevron in the button's label is the SF Symbol
  `"chevron.down"`. The popover for **presents-popover-below-button** is
  presented with `arrowEdge: .bottom`. The unmodified default type sizes
  cited under Appearance's **Font** entry come from
  `ThemeTypography.defaultStyle(_:)` in
  `packages/apple/AgenticDeveloperToolkit/Sources/Theme/ThemeTypography.swift`.
  The app's `\.theme` environment value is applied to that content via the
  shared `.themedRoot()` helper (once on `MCPChipsBar`'s root, and again on
  `MCPServerPicker` inside the popover, since a popover is its own window —
  see **reapplies-theme-inside-popover**); the view model retains its
  `registry.$clients` subscription in a `Set<AnyCancellable>` property for
  its lifetime. Declaring both `MCPChipsBarView` and `MCPChipsBarViewModel`
  `@MainActor` is what confines every read and write of
  `availableServerIds`, `serverNames`, and `activeServerIds` to a single
  execution context (see the Edge Cases "Concurrent access" entry). There is
  no UIKit code path in source; a UIKit port would keep the SwiftUI content
  but host it with `UIHostingController`, replace the `.popover` with a
  `UIPopoverPresentationController` (iPad) or a sheet (iPhone) — and, since
  Toggle rows have no fixed height in source, would need to give each row at
  least a 44pt touch target, since AppKit's `.checkbox` toggle style carries
  no such minimum.
- **WinUI 3**: Build the bar as a `StackPanel`
  (`Orientation="Horizontal"`, `Spacing="8"`) holding a `FontIcon` using a
  Segoe Fluent Icons server glyph in place of `"server.rack"`, and a
  borderless `Button` (`Style="{StaticResource TextBlockButtonStyle}"` or
  equivalent, mirroring `.buttonStyle(.borderless)`) whose `Content` is the
  same three-branch label text plus a `FontIcon` chevron-down glyph, with a
  `Flyout` attached via `Button.Flyout` — the direct analog of `.popover` —
  set to `Placement="Bottom"` to mirror `arrowEdge: .bottom`. Inside the
  `Flyout`, use a `StackPanel` (`Spacing="8"`, `Padding="14"`, `MinWidth="220"`)
  containing a `TextBlock` heading ("Active MCP Servers") and either a
  two-line `TextBlock` empty-state message or one `CheckBox` per sorted
  server id (`IsChecked` bound to `isActive(id)`, `Content` bound to
  `name`), mirroring `lists-one-toggle-row-per-server` and
  `row-label-falls-back-to-unknown`. WinUI resource/`ThemeResource` lookups
  flow into a `Flyout`'s content automatically since it shares the visual
  tree's resource dictionaries, so — unlike this source's
  `reapplies-theme-inside-popover` requirement — no manual theme-reapply
  step is needed; call this out to implementors as a deliberate platform
  difference.

