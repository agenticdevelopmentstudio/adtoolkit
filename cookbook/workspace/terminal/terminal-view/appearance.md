
- **Corner radius**: Not set — no rounding is applied; only a plain
  rectangular border is applied to the caret subview.
- **Padding**: Not applicable — this view lays out no content of its
  own; it only mutates an existing terminal-engine-owned subview's layer
  properties.
- **Font**: Not set — the terminal's font is entirely the underlying
  terminal engine's own.
- **Background**: Not set — this view sets no background color of its
  own; the terminal's background is entirely the underlying terminal
  engine's own.
- **Foreground/Text**: The caret's text color is set to the appearance's
  own text color only while the caret is hollow, so the glyph under the
  outline reads as ordinary text (per source: "nothing is reversed out
  of an outline"); it is cleared to its unset/default state while the
  caret is filled, leaving the terminal engine's own reversed-text color
  in effect.
- **Border**: The caret subview's layer border is `1` point wide in the
  appearance's own color while hollow, and `0` width with no color while
  filled.
- **Shadow**: Not set — no shadow customization appears in source.
- **Min/Max size**: Not set — this view defines no size constraint of
  its own; sizing is entirely the underlying terminal engine's own.

