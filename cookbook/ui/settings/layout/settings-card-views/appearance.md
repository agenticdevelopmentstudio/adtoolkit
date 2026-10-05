
- **Corner radius**: The card clips to the standard card-corner-radius
  value (10pt), using a continuous (squircle) corner style.
- **Padding**: A card row insets its content 14pt horizontal by 9pt
  vertical; the group container spaces its caption from its card by 6pt;
  the panel-inset operation pads a whole panel 20pt on all sides.
- **Font**: The group container's caption uses the caption text role — 11pt,
  regular weight, the platform's system font family, scaled by the active
  theme's size scale unless the theme overrides the caption style.
- **Background**: The card fills with the elevated-surface theme color.
  The default derivation is the theme's background blended 12% toward its
  foreground, unless the active theme supplies an explicit override for
  that role.
- **Foreground/Text**: The group container's caption text color tracks the
  secondary-text role — the theme's foreground dimmed 32% toward its
  background with a 3.0 minimum-contrast floor, unless overridden. The
  divider fills with the divider role — the background blended 10% toward
  the foreground, unless overridden.
- **Border**: None on any of the six pieces of this vocabulary; the card
  sets no stroke, and the divider is itself a filled hairline rather than
  a bordered shape.
- **Shadow**: None; no shadow appears anywhere in this vocabulary.
- **Min/Max size**: None fixed by the group container, card, card row, or
  divider — each sizes to its content plus the padding above. The search
  field reports its wrapped native control's own natural height as its
  height, and the proposed width (or the control's own natural width if
  none is offered) — "its own height, the width it is offered."

