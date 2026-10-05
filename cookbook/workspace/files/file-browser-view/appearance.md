
- **Corner radius**: None. The container, footer, and the add/remove
  controls apply no corner radius.
- **Padding**: Footer content: 8pt from the footer's leading edge, at
  most 8pt from its trailing edge, 4pt from its top, 4pt from its bottom.
- **Font**: Not applicable to the footer controls — both are constructed with
  no title text and rendered as an icon image only (a plus/minus glyph), so
  no font is set on them. No other text-bearing element is created directly
  by this component.
- **Background**: Root container — window-background theme role. Footer —
  surface theme role. Both fills repaint live on theme change.
- **Foreground/Text**: Not applicable. The footer controls carry no title
  text, only an icon image; the theme role controls only the fills above,
  not any icon tint (the controls' tint is left to the platform's default
  for an accessory-style control).
- **Border**: A one-point separator between the tree and the footer, using
  the platform's standard separator appearance (no custom color is used
  here).
- **Shadow**: None specified.
- **Min/Max size**: The root container is given an initial frame of 260×400
  when first built; no width/height constraints are attached to the
  container itself, so the final size is whatever the host's layout gives
  it. This is a starting frame, not an enforced minimum or maximum.
- **Footer button spacing**: The add/remove controls sit with 2pt horizontal
  spacing between them.

