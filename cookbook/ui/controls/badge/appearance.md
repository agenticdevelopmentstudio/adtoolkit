
- **Corner radius**: 5pt.
- **Padding**: 2pt (top/bottom) × 6pt (leading/trailing).
- **Font**: the current theme's caption style (`palette.font(.caption)`),
  kept in sync with theme changes; weight/size are not literal in this
  component's own source — they come from the palette's `.caption`
  definition.
- **Background**: filled → the caller-supplied `color`; outlined →
  clear/transparent.
- **Foreground/Text**: filled → computed black or white (see
  `computes-contrasting-text-color`); outlined → the caller-supplied
  `color`.
- **Border**: filled → none (width 0); outlined → 1pt solid,
  caller-supplied `color`.
- **Shadow**: none — the source sets no shadow-related properties.
- **Min/Max size**: none declared. The badge has no explicit width/height
  constraints; it sizes to fit its label via required horizontal
  content-hugging on both the label and the container view.

