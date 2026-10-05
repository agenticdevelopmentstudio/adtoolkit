
- **Reduce Motion**: Not applicable. The component contains no animation —
  title changes, dot color changes, and layout all happen through
  immediate property assignment and layout constraints; there is no
  transition or motion effect to reduce.
- **Increase Contrast**: Not applicable at this component's level. Every
  color the component uses comes from a theme-palette role
  (`.windowBackground`, `.divider`, `.success`, `.warning`, `.danger`,
  `.secondaryText`); the component contains no branch on an
  increase-contrast accessibility setting, so any contrast adaptation
  would live in the theme/palette system, not here.
- **Differentiate Without Color**: Already satisfied. The connection state
  is conveyed through the status label's text (`Connected` / `Connecting…`
  / the error string) in addition to the status dot's color (see
  **connection-state-in-text** above), so no state in this
  component is communicated by color alone.

