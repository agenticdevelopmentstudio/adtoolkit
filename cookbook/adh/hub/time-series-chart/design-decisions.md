
- **Decision**: One y scale only; a second measure of different scale needs a
  second chart.
  **Rationale**: Per source comment on the component in `time-series-chart.tsx`,
  the chart is for "a handful of series on ONE y scale (two measures of
  different scale belong in two charts, not a second axis)".
  **Approved**: pending
- **Decision**: At most four series, refused with a range error rather than
  truncated or given a generated colour.
  **Rationale**: Per source comment, "a fifth would need a generated hue, which
  is exactly the colour a reader can no longer tell apart — fold the tail into
  'Other' instead."
  **Approved**: pending
- **Decision**: A series keeps its colour slot by its position in the series
  list, never by its rank in the data.
  **Rationale**: Per the source comment on the series palette, assignment is
  fixed so a series keeps its colour as the data changes; the palette is the
  toolkit's own tagging hues, ordered so adjacent series stay apart for
  colour-blind readers.
  **Approved**: pending
- **Decision**: A null value is a gap in the line, never a zero.
  **Rationale**: Per the source comment on the point type, null means "no
  value", drawn as a break; `connectNulls` is off so a missing reading is not
  mistaken for a measured zero.
  **Approved**: pending
- **Decision**: A legend appears only from two series.
  **Rationale**: Per the source comment on the component, the legend exists so
  identity is never colour alone; a single series is named by the surrounding
  page, so the legend would repeat it.
  **Approved**: pending
- **Decision**: No entrance animation and no per-point dots.
  **Rationale**: The source disables animation and dots on every line, drawing
  a thin line with a marker only on the hovered point; the reason is not stated
  in source, so this records current behavior.
  **Approved**: pending

