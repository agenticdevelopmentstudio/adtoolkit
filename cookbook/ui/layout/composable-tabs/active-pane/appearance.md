
- **Corner radius**: None. The backdrop is a plain rectangular view layer
  with no corner radius set.
- **Padding**: Not applicable in the padding sense; the backdrop's fill
  subview is inset from the backdrop's own edges by the border inset (2pt) on
  all four sides, leaving that band for the border to draw in.
- **Font**: Not applicable. The component draws no text.
- **Background**: The theme's pane-backdrop color (a theme-overridable role,
  falling back to the elevated-surface role when the theme sets no override
  for it) fills the backdrop's layer; the fill subview inside it is painted
  with the window-background role.
- **Foreground/Text**: Not applicable. The component draws no text or icon.
- **Border**: 2 points wide on every pane, always. Color is the theme's
  active-pane-outline color for the active pane in a focused window with
  highlighting enabled, and the theme's pane-outline color otherwise.
- **Shadow**: None. The source sets no shadow on the backdrop.
- **Min/Max size**: None imposed by this file. The backdrop is sized by its
  pane's own layout (constraints applied by the surrounding pane view
  controller, not by this file).

