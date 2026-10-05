
- **Corner radius**: Not applicable — neither this component nor the
  wrapped view sets a layer or draws a custom shape; both compose stock
  text controls.
- **Padding**: The wrapped view's row inserts a flexible spacer between
  the label and text field, sets the row's spacing to the button role's
  default row spacing (8pt, applied to the label→spacer gap), and zeroes
  the spacer→field gap — the same row shape and spacing math several
  sibling row controls in this system use. This component's own edge
  pinning adds 0pt of outer padding of its own; the wrapped view's own
  edge-pinning (or the content-width variant when a fixed label width is
  set) likewise adds nothing beyond that internal 8pt/0pt spacing.
- **Font**: The label uses the button text role, resolving to that role's
  default style: 13pt, medium weight, proportional system font, scaled by
  the active theme's size scale. The text field uses the code text role,
  resolving to that role's default style: 12pt, regular weight, the
  system monospaced font, also scaled by the size scale — chosen so a
  changing value doesn't reflow the field.
- **Background**: The label — none (transparent). The text field — source
  never overrides its border, bezel, or background settings on it; it
  stays a plain, default-initialized text field, which keeps the
  platform's standard bezeled, opaque text-field background rather than
  being transparent like the label.
- **Foreground/Text**: The label (primaryText role) resolves to the active
  theme's foreground color at full strength, repainted live on a theme
  change. The text field's text color is set directly to the same
  primaryText role, applied through the theme-observation mechanism rather
  than through the label's own theming path, also repainted live on every
  theme change.
- **Border**: The label — none. The text field — no border property is
  set in source, so it keeps the platform's default bezel, drawn by the
  platform rather than by this component.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: The text field's width is fixed to the constant field
  width (52pt via this component's own default; the wrapped view's own
  uncalled default is 72pt — see Design Decisions). No height constraint
  is set on either the label or the text field; height comes from each
  control's intrinsic content size within the row.

