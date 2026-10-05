
- **Role/trait**: No explicit accessibility-role call appears anywhere
  in source; the container, each row, and each swatch are plain elements
  with whatever default accessibility role the platform assigns to an
  untouched view (effectively none). Whether the grid, its rows, or its
  swatches should be exposed to assistive technology as discrete
  elements is an open design question that source does not answer.
- **Label requirements**: No swatch carries an accessible name or value
  describing the color it shows (e.g., a color name or hex value); a
  screen reader user landing on a swatch has no source-provided way to
  learn which color it represents. Default SHOULD, pending review:
  swatch construction SHOULD assign an accessible label using a
  caller-supplied name for that color when one is available, falling
  back to a computed hex string (e.g. `#RRGGBB`) when no name is
  supplied. What would settle it: review approving this default, or
  specifying a different label format.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading state and never disables itself (see
  States); there is no state transition to announce.
- **Minimum tap target**: Not applicable — this is a pointer/
  trackpad-driven composition with no touch input path in source, and,
  per the States section, no interactive element exists at all to size a
  tap target for.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. Each swatch's 0.5pt border takes its color from the theme's border role through a theme observer, and the swatch fill is the caller-supplied color; contrast of the border against the background is whatever the active theme resolves.

