
- **renders-rounded-pill**: Component MUST render its background as a
  rounded rectangle with a corner radius of 5pt.
- **displays-caller-text**: Component MUST display the exact `text` string
  passed at construction or restyle as the label's content.
- **defaults-to-filled-style**: Component MUST use the filled style when no
  `style` argument is supplied at construction.
- **paints-filled-background**: In the filled style, Component MUST set its
  background to the caller-supplied `color` and its border width to 0.
- **computes-contrasting-text-color**: In the filled style, Component MUST
  set the label's text color to black when the background color's
  luminance (`0.299·R + 0.587·G + 0.114·B` in the sRGB color space) is
  greater than 0.6, and to white otherwise. This heuristic does not compute
  a WCAG contrast ratio and is not guaranteed to meet any minimum numeric
  ratio against an arbitrary caller-supplied `color` — see the open
  question on minimum-contrast-ratio and the related Design Decision.
- **falls-back-to-white-on-unconvertible-color**: Component MUST use white
  as the filled-style label text color when the caller-supplied `color`
  cannot be converted to the sRGB color space.
- **paints-outlined-appearance**: In the outlined style, Component MUST use
  a clear (transparent) background, a 1pt border in the caller-supplied
  `color`, and set the label's text color to that same `color`.
- **supports-in-place-restyle**: Component MUST update its displayed text,
  color, and style when the restyle operation is called on an existing
  instance, without requiring a new instance.
- **resets-style-to-filled-by-default-on-update**: Calling the restyle
  operation with text and color but no explicit style argument MUST reset
  the badge to filled, regardless of the badge's current style, because
  the restyle operation's style parameter defaults to filled independently
  of any stored state. This is a documented footgun (see Design
  Decisions): callers SHOULD NOT rely on the restyle operation preserving
  the badge's current style, and SHOULD pass style explicitly on every
  call where a non-default style must be kept.
- **applies-fixed-content-padding**: Component MUST inset its label by 6pt
  from the leading and trailing edges and 2pt from the top and bottom
  edges.
- **centers-label-text**: Component MUST center-align the label's text
  within the badge.
- **tracks-theme-caption-font**: Component MUST keep the label's font
  synchronized with the current theme's caption font
  (`palette.font(.caption)`), updating it whenever the theme changes.
- **sizes-to-fit-content**: Component MUST size itself to its content's
  intrinsic width rather than stretching to fill available horizontal
  space — both the badge and its label carry a required horizontal
  content-hugging priority.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **rejects-storyboard-instantiation**: The control MUST be constructible only in code. Constructing it from a serialized or archived representation (such as a nib or storyboard) MUST be refused as a programmer error that terminates, producing no instance.
- **prefers-semantic-palette-colors**: Callers SHOULD supply `color` values
  drawn from a `SemanticPalette` rather than arbitrary raw colors, per the
  component's documented intent ("typically drawn from a
  `SemanticPalette`"). This is a usage guideline for callers, not behavior
  the component itself can enforce or verify — no test vector applies (see
  Design Decisions).

