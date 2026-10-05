
- **Corner radius**: 5pt.
- **Padding**: The label is pinned 6pt in from the view's leading and
  trailing edges and centered vertically; there is no separate top/bottom
  padding constant — vertical position is centering within the fixed 22pt
  height, not an inset.
- **Font**: `palette.font(.button)`, which defaults to a 13pt, medium
  weight, proportional system font; the size scales with the active
  theme's `sizeScale` and the label repaints on every theme change (see
  theme-change-repaint).
- **Background**: Set to `palette.controlBackgroundColor` (the theme's
  `controlBackground` role, resolved to a fixed color per the active
  theme — not a system-dynamic color).
- **Foreground/Text**: See shortcut-presence-text-color — `primaryTextColor`
  when a shortcut is shown, `placeholderTextColor` otherwise.
- **Border**: 1pt width (a fixed constant, not theme-scaled); color per
  recording-state-border-color.
- **Shadow**: Not applicable — no shadow property is set or drawn anywhere
  in this component's own source.
- **Min/Max size**: Height is fixed at exactly 22pt. Width has a minimum of
  132pt and no explicit maximum; how wide the view actually grows is left
  to whatever layout hosts it (a Key Command Row View).

