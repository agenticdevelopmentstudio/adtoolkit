
- **draws-one-line-per-series**: The component MUST draw exactly one line for
  each entry in the series list, reading each line's values from the point key
  named by that series.
- **x-label-from-point**: The component MUST place each point at the x position
  labelled by that point's `x` value, in the order the points are given.
- **gap-for-null-value**: A point whose value for a series is `null` MUST be
  drawn as a break in that series' line and MUST NOT be drawn as a zero; the
  line MUST NOT be connected across the gap.
- **single-y-scale**: All series MUST share one y axis; the component MUST NOT
  offer a second axis.
- **series-colour-by-position**: A series MUST take its colour from a fixed
  ordered palette of four categorical colours by its position in the series
  list (first blue, second orange, third violet, fourth pink), never by its
  rank in the data.
- **palette-tokens-with-fallback**: Each palette colour MUST be read from a
  theme token with a literal fallback value, so the colour is hue-stable across
  themes.
- **refuses-fifth-series**: The component MUST refuse a series list longer than
  the palette (more than four) by raising a range error naming the limit and the
  count received, and MUST NOT draw a chart in that case.
- **legend-from-two-series**: The component MUST show a legend naming every
  series when there are two or more series, and MUST NOT show a legend for a
  single series.
- **legend-uses-series-label**: Each series' line, legend entry, and tooltip row
  MUST be named by that series' `label`, not its `key`.
- **crosshair-tooltip**: The component MUST show a tooltip, with a crosshair
  cursor, that lists every series' value at the hovered x position under that
  x label.
- **format-applies-to-axis-and-tooltip**: The component MUST pass every numeric
  value shown on the y axis and in the tooltip through the caller's format
  function, which defaults to rendering the number as-is.
- **tooltip-null-placeholder**: The tooltip MUST render a value that is not a
  number as an em dash, and MUST NOT pass it to the format function.
- **height-parameter**: The component MUST render the plot at the given height
  in pixels, defaulting to 240, and MUST size the plot's width to its container.
- **no-point-dots**: Lines MUST be drawn without a dot on every point; only the
  hovered point MAY show an enlarged marker.
- **no-animation**: The component MUST draw its lines without an entrance
  animation.
- **themed-by-tokens**: Axis text, grid lines, tooltip surface, tooltip border,
  and tooltip text MUST take their colours from theme tokens rather than literal
  colours.
- **horizontal-grid-only**: The grid MUST draw horizontal lines only, at reduced
  opacity.
- **no-mutable-state**: The component MUST hold no state of its own; it MUST
  render only from its inputs.

