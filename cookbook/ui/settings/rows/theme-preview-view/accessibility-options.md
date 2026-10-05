
- **Reduce Motion**: Not applicable — the show operation and every
  sample-building helper perform an instantaneous full teardown and
  rebuild; no animation context, animator, or transition of any kind
  appears anywhere in source, so there is no motion for Reduce Motion to
  substitute for.
- **Increase Contrast**: Not applicable at this component's own level —
  every color is read through the palette's role lookup
  (semantic-palette-derivation); the component itself contains no separate
  Increase Contrast branch, so it inherits whatever contrast behavior the
  active palette/theme provides without any code of its own to adjust.
- **Differentiate Without Color**: Supported for the status sample — each
  of the four badges pairs its status color with an explicit text label
  ("Success"/"Warning"/"Error"/"Info"), so status is never conveyed by hue
  alone (contrast this with the embedded swatch grid's raw color swatches,
  which carry no label — see that recipe's own note). The chrome sample's
  "Button" vs. "Selected" pills are likewise distinguished by their own
  text, not color alone.

