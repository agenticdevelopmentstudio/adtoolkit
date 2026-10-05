
- **Reduce Motion**: Not applicable — source contains no animation or
  transition call; every rebuild replaces subviews instantaneously.
- **Increase Contrast**: Not applicable to the swatch fill — the fill is
  the caller-supplied data color itself, not a themed UI color, so there
  is nothing for Increase Contrast to adjust without changing the data
  being displayed. The swatch border's color comes from the theme's
  border semantic role (see **renders-swatch-style**); no separate
  Increase Contrast handling exists in source itself.
- **Differentiate Without Color**: this component's entire purpose is
  conveying distinct colors as colors, with no accompanying label,
  pattern, or text differentiator in source — see **Label requirements**
  in Accessibility, which is the same gap that would let a
  Differentiate Without Color user distinguish swatches without relying
  on color perception alone.

