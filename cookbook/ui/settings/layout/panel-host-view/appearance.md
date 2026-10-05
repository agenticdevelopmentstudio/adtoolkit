
- **Corner radius**: None. Neither the component nor its content
  container sets a corner radius anywhere in source.
- **Padding**: The content container is pinned to the component's edges
  with 0pt inset on all four sides. Installed content is pinned to the
  content container's edges with 0pt inset on all four sides. The help
  button sits 12pt inside the content container's top and trailing edges.
- **Font**: Not applicable — the source draws no text of its own; its
  only visual element besides hosted content is an image-only help
  button, which carries no font.
- **Background**: None set. Neither the component nor its content
  container configures a background of its own in source; whatever shows
  through is the hosted content's own background or the window's.
- **Foreground/Text**: The help button's tint color is the theme's
  accent-color role while help is visible, the theme's secondary-text-color
  role while it is not (see **help-button-tint-reflects-visibility**).
- **Border**: None — the help button is explicitly borderless; nothing
  else in the source draws a border.
- **Shadow**: None — no shadow is drawn or configured anywhere in the
  source.
- **Min/Max size**: None declared on the component itself — no explicit
  width or height constraint appears in source. It fills whatever frame
  its container (the split's detail pane) gives it.

