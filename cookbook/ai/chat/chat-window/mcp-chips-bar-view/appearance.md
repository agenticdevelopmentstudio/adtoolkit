
- **Corner radius**: Not applicable — no corner radius or custom layer is
  set anywhere in source; any rounding on the popover's chrome comes from
  the platform's own default popover appearance.
- **Padding**: Bar row: 12pt horizontal / 6pt vertical, 8pt spacing
  between the icon, the button, and the trailing spacer. Button's inner
  row (label + chevron): 4pt spacing, no explicit padding. Picker
  column: 14pt on all sides, 8pt spacing between rows.
- **Font**: `theme.font(.caption)` for the bar button's label/chevron and
  for the picker's empty-state message; `theme.font(.heading)` for the
  picker's "Active MCP Servers" heading. The unmodified default styles for
  these roles are 11pt regular (caption) and 15pt semibold (heading), each
  additionally scaled by the active theme's size-scale factor (see Platform
  Notes for where these defaults are defined). Each server row's label and
  the checkbox's own title set no explicit font, so they render in the
  platform's default body text style.
- **Background**: Not set explicitly by this file; both roots (the bar
  and, separately, the server picker inside the popover) sit on whatever the
  shared theming mechanism paints — the active theme's window background —
  since each call site accepts that mechanism's default of painting a
  background (see Platform Notes).
- **Foreground/Text**: `theme.secondaryText` on the rack icon and the
  picker's empty-state message; `theme.accent` on the button's label and
  chevron; the heading and each row's label use the primary text color the
  shared theming mechanism applies at each host root, not a color this file
  sets itself.
- **Border**: Not applicable — no border is drawn or configured anywhere in
  source.
- **Shadow**: Not applicable — no shadow is drawn or configured in source;
  the popover's window shadow is the platform's own system chrome.
- **Min/Max size**: The bar itself has no fixed frame — it sizes to its
  content plus padding, and is stretched to fill whatever bounds its
  containing element gives it (see **fills-parent-bounds**). The picker has a
  minimum width of 220pt and no maximum; the popover otherwise sizes itself
  to that content's fitting size.

