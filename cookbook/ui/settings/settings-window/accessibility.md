
- Role/traits: a standard system window with title-bar close/minimize/zoom
  controls; the header bar's navigation and help controls are plain
  segmented-control and button widgets hosted in custom-view header-bar
  items, and the panel-title item hosts a plain text label.
- Accessibility identifiers: the help control's accessibility identifier is
  fixed at `"ComposableSettings.help"`. Neither the navigation control nor
  the panel-title item is given an explicit accessibility identifier in
  this file.
- Label requirements: the navigation control's combined accessibility label
  is "Back and forward"; its two segment icons carry the accessibility
  descriptions "Back" and "Forward". The help control's accessibility
  description is fixed at "Help" for its whole lifetime (see
  **keeps-help-accessibility-name-stable**).
- Announce state changes: the help toggle communicates open/closed through
  icon shape (outline vs. filled) and tooltip text, not tint alone (see
  **swaps-help-tooltip-by-drawer-state** and
  **shows-filled-glyph-when-drawer-open**).
- Minimum control size: this file sets no explicit frame for the navigation
  control or help control, so both size themselves per the platform's
  standard icon-only header-bar sizing, consistent with this codebase's
  other header-bar controls rather than a value this file decides on its
  own; on a pointer-driven platform there is no mandated minimum
  touch-target size to meet (see Platform Notes for touch-platform sizing
  considerations).
- Keyboard/focus: the navigation control and help control are ordinary
  keyboard-focusable controls (Tab to focus, Space/Return to activate); the
  segmented control provides its own arrow-key segment navigation. This
  file customizes neither the focus order nor any keyboard shortcut for
  these controls.
- Color/contrast: header-bar and label colors are read from the shared
  theme palette; contrast is a design-system-level concern this file does
  not decide, per
  `agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages`.
- **minimum-contrast-ratio**: The window MUST draw the panel-title item's text in the theme's primary-text role and tint the help control from the theme's secondary-text/accent roles, each against whichever theme surface renders behind the transparent, unified header bar. The window performs no contrast-ratio check of its own between those roles and their background; contrast is whatever the active theme's palette provides.

