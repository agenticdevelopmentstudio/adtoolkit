
- **SwiftUI**: Build a `Menu` whose label is the computed summary string
  (mirroring the title-refresh operation's three branches), containing a
  `Button` ("Any") that clears the selection, a `Divider`, then a `Toggle`
  per choice bound to that choice's membership in the selection set — on
  macOS, a `Toggle` inside a `Menu` renders as a checkable menu item, the
  SwiftUI analog of a checked menu item. Gate the write with an equality
  check before invoking the caller's change handler, mirroring
  fires-on-change-on-actual-change.
- **Compose**: Use a `Box` with a `TextButton`/`OutlinedButton` showing the
  summary text, opening a `DropdownMenu` of `DropdownMenuItem`s, each with a
  leading `Checkbox` (or check icon) reflecting membership, plus a
  leading "Any" item that clears the set. Note a translation difference:
  Compose's `DropdownMenuItem.onClick` conventionally dismisses the menu
  (`expanded = false`) unless the call site explicitly keeps it open, so
  matching the source's "menu closes on every pick" behavior is the
  default, but a Compose implementation that wants to let one visit toggle
  several boxes would have to deliberately diverge from this recipe.
- **React/Web**: A `<button>` with `aria-haspopup="menu"` and
  `aria-expanded`, showing the summary text, disclosing a `role="menu"`
  container of `role="menuitemcheckbox"` entries with `aria-checked`
  reflecting membership, plus a `role="menuitem"` "Any" entry that clears
  every `aria-checked`. Note a translation difference: the ARIA Authoring
  Practices convention for `menuitemcheckbox` keeps the menu open across
  multiple picks, unlike the source's per-pick close, so matching the
  source exactly means closing the menu explicitly after each selection.
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/UI/Controls/MultiChoiceFilterButton.swift`.
  A macOS-only (`import AppKit`) `NSPopUpButton` subclass, `@MainActor`,
  configured `pullsDown: true`. `confines-to-ui-thread` is enforced by
  the class being declared `@MainActor`, so construction or mutation from
  off the main actor fails to compile — a static, compile-time check
  rather than a vector observed by running the program.
  `rejects-coder-initialization` is implemented as a fatal error on
  `init?(coder:)`, since this component provides no Interface
  Builder/`NSCoding` support: attempting `MultiChoiceFilterButton(coder:
  someCoder)` traps with a fatal error and no instance is returned.
  `disables-autoresizing-mask-translation` sets
  `translatesAutoresizingMaskIntoConstraints = false` at initialization so
  the button is positioned by Auto Layout rather than by an autoresizing
  mask — pure layout plumbing with no independently observable behavior of
  its own. It builds a checkable `NSMenu` by hand (label item, "Any",
  separator, one item per choice with `representedObject` holding the
  choice's id — neither the label item nor "Any" carries one, which is why
  the checkmark-resync operation skips both), toggles membership in a
  `Set<String>` from each item's target-action, and repaints its title and
  theme colors through `refreshTitle()`/`applyTheme(_:)`. `refreshTitle()`
  satisfies **refreshes-title-synchronously** by calling
  `synchronizeTitleAndSelectedItem()` immediately after recomputing item
  0's title (a pull-down otherwise keeps the stale title until its menu is
  next reset), and satisfies **resizes-for-longer-titles** by calling
  `invalidateIntrinsicContentSize()` right after that, so the new width is
  measured immediately instead of truncating inside the previous width.
  `initializes-selection-empty` holds because the initializer never
  assigns `selection` itself, so its declared default bypasses the
  property's `didSet` observer (the same observer that drives
  `refreshTitle()`/`onChange` on every later change). The foreground tint
  color is `contentTintColor`; the font path is
  `ThemeTypography.defaultStyle` scaled by `readerScale`, applied and
  reapplied via `ThemePaletteObserver` (falling back to the Solarized Dark
  theme when no `ThemeManager` exists). Checked/unchecked state is
  `NSMenuItem.state = .on`/`.off`. No `controlSize` is set on the button.
  There is no UIKit code path in source — `NSPopUpButton`/`NSMenu` have no
  direct UIKit counterpart; a UIKit/iOS port would replace this with a
  `UIButton` whose `menu` is a checkable `UIMenu` (`UIAction`s with
  `.state = .on`/`.off`; leave `UIMenu.Options` without `.displayInline`, so
  the whole list of checkable actions stays visible instead of collapsing
  into a submenu), setting `showsMenuAsPrimaryAction = true`.
- **WinUI 3**: Build a `DropDownButton` whose `Flyout` is a `MenuFlyout`
  containing one `ToggleMenuFlyoutItem` per choice — `ToggleMenuFlyoutItem.
  IsChecked` is the WinUI analog of `NSMenuItem.state`, and, like a
  checkable `NSMenu`, a `MenuFlyout` closes after an item is invoked by
  default, matching the source's per-pick close. Add a plain
  `MenuFlyoutItem` titled "Any" above a `MenuFlyoutSeparator` that clears
  every `ToggleMenuFlyoutItem.IsChecked`. Recompute the `DropDownButton`'s
  `Content` from a summary string mirroring the title-refresh operation's
  three branches on every selection change — from each
  `ToggleMenuFlyoutItem.Click` handler, the "Any" item's click handler, and
  any programmatic selection-setting entry point alike — since WinUI has
  no built-in pull-down title binding the way `NSPopUpButton` redraws item
  0's title. Set `AutomationProperties.Name` on the `DropDownButton` to the
  current summary text as well, so Narrator's accessible name stays in
  sync the way `NSPopUpButton`'s native title-based name does
  automatically.

