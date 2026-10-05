
- **clamps-column-count**: Component MUST clamp the initializer's
  `columns` parameter to a minimum of 1, so a caller-supplied value of 0
  or a negative number never produces a zero- or negative-width row.
- **arranges-swatches-in-rows**: Component MUST lay out `colors` into
  consecutive rows of at most `columns` swatches each, filling each row
  in the order the colors appear in the array before starting the next
  row.
- **builds-hierarchy-on-init**: Component MUST build its full row/swatch
  view hierarchy once during initialization, from the `colors` and
  `columns` values supplied to that initializer.
- **replaces-colors-and-rebuilds**: Component MUST, when a new set of
  colors is supplied after construction, replace its stored colors with
  the supplied array and MUST display exactly the new colors afterward,
  with no swatch from the previous set remaining in the view hierarchy.
  See Design Decisions for the full-rebuild strategy source uses to
  satisfy this.
- **pins-container-to-edges**: Component MUST pin its internal container
  to all four edges of itself with no additional constant.
- **uses-uniform-spacing**: Component MUST apply the single `spacing`
  initializer parameter as both the internal container's row-to-row
  (vertical) spacing and each row's swatch-to-swatch (horizontal)
  spacing, so the gap between rows equals the gap between swatches
  within a row.
- **sizes-swatch-fixed**: Each swatch MUST be constrained to the
  constructor-supplied `swatchSize` width and height via activated
  layout constraints (default 22 by 22), independent of the swatch's
  color content.
- **renders-swatch-style**: Each swatch MUST render with a 3pt corner
  radius, a background fill equal to the corresponding color value, and
  a 0.5pt-wide border whose color is set, and re-set on every theme
  change, to the active theme's border role color.
- **renders-empty-grid**: Component MUST render zero rows when `colors`
  is empty, rather than trapping or throwing.
- **shortens-final-row**: Component MUST render a final row containing
  fewer than `columns` swatches when `colors.count` is not evenly
  divisible by `columns`.
- **single-row-when-columns-exceeds-count**: Component MUST render all
  colors in a single row shorter than `columns` when `columns` exceeds
  `colors.count`.

Construction requires its colors and layout parameters; the
deserializing construction path is rejected, a platform mechanic rather
than a normative requirement here — see traps-on-coder-init
under Platform Notes.

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

