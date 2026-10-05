
- **Role/trait**: Not observable beyond the platform's defaults — no
  custom accessibility-role or accessibility-element call appears in
  source. The slider and text elements each carry the platform's built-in
  accessibility role (slider, static text) automatically.
- **Label requirements**: The title label and the slider are laid out as
  sibling elements in the same row, but source sets no accessible-name link
  (or equivalent) on the slider linking it to the title text — unlike a
  sibling row over the same view model, which links its control's
  accessible name to its title. Assistive-technology focus on the slider is
  therefore not programmatically tied to the row's title text.
- **Announce state changes (e.g., loading, disabled)**: Not applicable — the
  component has no loading state and never disables itself (see States);
  there is no state transition to announce.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path in source); a touch-target minimum is
  touch-interface guidance, not a pointer-interface requirement.

