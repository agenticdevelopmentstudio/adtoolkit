
- **Corner radius**: Not applicable — the component draws no shape of its
  own; no layer or corner radius is configured.
- **Padding**: 0pt of the component's own — the stack's top/leading/
  trailing/bottom are pinned directly to the component's edges with no
  additional constant (see Platform Notes for the pinning mechanism). The
  internal gap between the hint label and the dismiss button is 8pt (the
  standard row-spacing token).
- **Font**: the hint label tracks the current theme's caption text role;
  weight/size are not literal here — they come from the theme's caption
  definition. The dismiss button's font is the platform's own default
  system control font for its compact rounded style; no font is set
  explicitly on it.
- **Background**: Not applicable — no background color or layer is set on
  the component itself.
- **Foreground/Text**: the hint label uses the theme's secondary text
  color, a theme-resolved semantic color; the dismiss button's title
  color is the platform's default system coloring for its style, not set
  explicitly.
- **Border**: Not applicable — no border is drawn or configured.
- **Shadow**: Not applicable — no shadow is drawn or configured.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set on the component itself; because the stack is pinned
  to all four edges, the component's size follows the stack's own
  constraint-driven size (the hint label's wrapping width and the dismiss
  button's intrinsic size).

