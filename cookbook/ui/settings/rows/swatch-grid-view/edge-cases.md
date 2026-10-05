
- Null/empty input: colors defaults to an empty array and is a
  non-optional array. When empty, the row-building loop never executes,
  so the view ends up with zero rows and zero swatches — the
  **renders-empty-grid** requirement.
- Boundary values — colors count not evenly divisible by columns: the
  last row contains `colors.count % columns` swatches rather than a full
  `columns` — the **shortens-final-row** requirement, directly
  traceable to the row-building loop's bounds.
- Boundary values — `columns` exceeding `colors.count`: all colors
  render in a single row shorter than `columns` — the
  **single-row-when-columns-exceeds-count** requirement, following from
  the same loop bounds as above.
- Concurrent access: Not applicable — the component is confined to the
  UI thread, so all access to colors, the container, and every mutating
  method is serialized; there is no code path by which two threads
  mutate the view simultaneously.
- Error states: Not applicable — every operation in source (property
  assignment, layer configuration, constraint activation) is synchronous
  and non-throwing; no error-producing API appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only renders caller-supplied color values.
- Dynamic/appearance-adaptive input color: swatch construction sets the
  swatch's fill to the supplied color once, at creation time, and never
  revisits that assignment. Only the swatch's *border* color is
  re-applied on a theme change. If a caller passes a dynamic
  (appearance-adaptive) color as a swatch color, the swatch's fill MAY
  remain visually stale after a system appearance change until the
  caller triggers a full rebuild by replacing the colors again; this is
  current, source-traceable behavior — not a named MUST requirement —
  and is recorded as a documented quirk in Design Decisions rather than
  corrected here.

