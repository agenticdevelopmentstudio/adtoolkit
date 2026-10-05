
- **Corner radius**: The container and the component itself have no
  corner radius (neither is layer-backed with one at that level). Each
  individual swatch has a fixed 3pt corner radius, not configurable
  through any initializer parameter.
- **Padding**: The component contributes 0pt of outer padding — the
  container is pinned to all four edges with no additional constant.
  Internally, rows are spaced `spacing` apart vertically (default 4pt)
  and swatches within a row are spaced `spacing` apart horizontally (the
  same value), per uses-uniform-spacing.
- **Font**: Not applicable — the component draws no text; its rows and
  swatches have no font property.
- **Background**: The component and its container have no background of
  their own (transparent; neither is layer-backed at that level). Each
  swatch's background is the corresponding color's fill, set once when
  the swatch is created and never re-applied afterward except by a full
  rebuild (construction or a color replacement) — see Edge Cases for the
  consequence for a dynamic/appearance-adaptive input color.
- **Foreground/Text**: Not applicable — no text or foreground-colored
  content exists anywhere in source.
- **Border**: Each swatch has a 0.5pt border whose color is bound to the
  active theme's border semantic role and kept live on a theme change
  (see renders-swatch-style). Neither the container nor the component
  itself has a border.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in source.
- **Min/Max size**: Not applicable at the grid level — no explicit
  min/max width or height constraint is set on the component or its
  container; the grid's overall size is the sum of its rows' intrinsic
  sizes. Each individual swatch, however, is fixed (not merely
  constrained a minimum) to its configured size per sizes-swatch-fixed.

