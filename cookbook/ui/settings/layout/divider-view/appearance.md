
- **Corner radius**: None; the component never applies a corner radius.
- **Padding**: Not set by the component itself; it has no internal content
  to pad. The space around the line is entirely up to whatever container
  lays it out.
- **Font**: Not applicable — the component renders no text or other
  font-dependent content.
- **Background**: The component's fill color is set to the resolved theme
  scope's divider role. This is reapplied on initialization, on every
  theme change, and on the component's own scope change (and, in the
  source implementation, on every native repaint pass — see Platform
  Notes).
- **Foreground/Text**: Not applicable — the component has no text or
  foreground content; its fill is its only visual surface.
- **Border**: None; the component never applies a border.
- **Shadow**: None; the component never applies a shadow.
- **Min/Max size**: Height fixed at 1.0pt (the divider-thickness design
  token); no width constraint of its own — width is determined entirely
  by whatever layout the container applies.

