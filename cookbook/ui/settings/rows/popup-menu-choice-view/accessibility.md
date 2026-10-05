
- **Role/trait**: Not customized beyond the title-element link below — no
  explicit accessibility role override appears in source; the popup
  carries the platform's own built-in accessibility role for a pop-up
  button control.
- **Label requirements**: Component MUST associate the popup's accessible
  name with the visible label — per the design rationale, "the visible
  title label sits beside the popup but the platform doesn't associate
  them, so a screen reader would announce the popup with no name"; the
  visible label supplies the accessible name instead of a separate
  accessibility label string. Each menu item's own accessible name comes
  from its title (the choice's label); an attached symbol image is given
  no separate accessibility description, so the image itself contributes
  no separate spoken description beyond the item's title.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself in source
  (see States); the selected value is announced by the popup's own native
  accessibility value reporting when the selection changes, which this
  component does not override.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  control composition (no touch input path in source); the 44×44pt
  minimum is touch guidance, not a pointer-interface requirement. This
  component sets no reduced control size on the popup, so it keeps the
  platform's regular system click-target metrics.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label's color comes from the theme's primary-text role through the shared row-label factory, and when the row is disabled the label is drawn at a fixed 40% opacity; the popup draws its current value in the platform's own style.

