
- **Role/trait**: Not observable beyond the platform's defaults — no
  custom accessibility-role or accessibility-element call appears in
  source. The color well and text elements each carry the platform's
  built-in accessibility role (color well, static text) automatically.
- **Label requirements**: The label and the color well are laid out as
  sibling elements in the same row, but source sets no accessible-name
  link (or equivalent) on the color well linking it to the label —
  confirmed by comparison with several sibling row controls in this
  system, which each link their control's accessible name to their label,
  but this component does not do so for the color well. The color well
  relies entirely on the platform's own default accessibility role, with
  no explicit, programmatic link from the color well to the row's title
  text.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself (see
  States); there is no state transition to announce.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path in source); a touch-target minimum is
  touch-interface guidance, not a pointer-interface requirement.

