
- **Corner radius**: None — no rounding is applied to the glyph.
- **Padding**: None — the glyph fills the component's bounds exactly (see
  **glyph-bounds-layout**); there is no internal inset.
- **Font**: Not applicable in the text sense — the component renders an icon
  glyph, not text. The glyph is rasterized at an 11pt, semibold weight.
- **Background**: None/transparent — no background fill is set behind either
  the component or its glyph.
- **Foreground/Text**: The glyph's tint — the active theme's accent,
  tertiary-text, or warning color role (see **state-based-tint**), or the
  system tertiary label color before the first theme apply.
- **Border**: None — no border is drawn.
- **Shadow**: None — no shadow is applied.
- **Min/Max size**: Fixed, not a range — both width and height are pinned to
  exactly 13pt (see **fixed-glyph-size**). The glyph scales to fit that fixed
  13×13pt box without distortion, preserving its aspect ratio.

