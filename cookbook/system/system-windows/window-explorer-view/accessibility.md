
- Role/traits: standard platform controls only — a checkbox-styled toggle
  for every selection control (section select-all and per-window rows), a
  borderless button for refresh and a bordered button for "Open Settings",
  and a list with sections for the grouped content. No custom accessibility
  role or trait values are set anywhere in the file.
- Label requirements: each toggle's accessible label is its visible label
  content — the section header's icon/name/count row for the select-all
  toggle, and the title/dimensions/badge column for a row toggle — since
  no explicit accessibility label is set on either. The "Open Settings"
  button carries its own visible text as its label — see
  **refresh-button-label** for the refresh button.
- **refresh-button-label**: The refresh button is icon-only (a refresh-arrow icon) and sets no explicit accessibility label; the screen reader gets only the icon's implicit description plus a "Refresh window list" help tooltip, which is exposed as a tooltip and accessibility hint, not as the label.
- Announce state changes: the loading, empty, and populated states are
  distinct view trees that the framework swaps directly (no text or state
  is kept visible across the transition); no accessibility-trait update,
  announcement posting, or focus-move call accompanies any of these swaps,
  so a screen-reader user gets no explicit announcement and no
  accessibility-focus change when a scan finishes (loading to
  list/empty).
- Minimum control size: this is a pointer-driven surface with no mandated
  minimum touch-target size (unlike a touch platform); the view uses
  standard checkbox-style control sizing throughout — a small control size
  on the banner's "Open Settings" button, and the system default size
  everywhere else — consistent with this being a pointer/keyboard surface
  rather than a value this view decides on its own.
- Keyboard/focus: every interactive element (toggle, button) is a
  standard, keyboard-focusable platform control; no custom key
  handling or focus trapping is added in this file.
- Color/contrast: all text and background colors resolve through the shared
  theme palette, except the context badge's stored-color-or-fallback-blue
  color, which is not a palette color; contrast is a design-system-level
  concern outside this view's own decisions, per
  `agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages`.

