
- **Corner radius**: `4pt` on the status dot's backing layer, which on an
  8×8pt square renders as a filled circle. No other view sets a corner
  radius directly; the pause/clear buttons' corner radius (if any) belongs
  to the themed secondary button, a separate themed control.
- **Padding**: Leading toolbar cluster — 12pt from the toolbar container's
  leading edge, vertically centered. Trailing toolbar cluster — 12pt from
  the toolbar container's trailing edge, vertically centered. Within each
  cluster, 8pt spacing between arranged views.
- **Font**: Not applicable directly. The pause/clear buttons (the themed
  secondary button) and the status label (the themed label, constructed
  with a caption text role) resolve their own font from the active
  theme's text roles; the component sets no font of its own.
- **Background**: Root container — `.windowBackground` theme role, via the
  themed background view. The toolbar container has no explicit fill of its
  own. The status dot's fill is a background color driven by connection
  state (`.success` / `.warning` / `.danger`), not a static background.
- **Foreground/Text**: The status label is constructed with the
  secondary-text role, so its text color tracks that role; its text
  content is the same three-way connection string used for the tooltip.
  Pause/Clear button title colors are the themed secondary button's own
  concern, not set by the component.
- **Border**: The divider between the toolbar and the log view is a themed
  separator view with the `.divider` role, a 1pt hairline spanning the root
  view's width.
- **Shadow**: None specified.
- **Min/Max size**: The root view enforces a floor, equal to
  `minimumContentSize` (default `600×400`, overridable), on its own width
  and height. No maximum size is set.
- **Status dot size**: Fixed `8×8pt` (see Behavioral Requirements).

