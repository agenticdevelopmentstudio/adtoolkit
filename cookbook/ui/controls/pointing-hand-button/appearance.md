
- **Corner radius**: Not set by this component; governed entirely by the
  platform's default button bezel style — no bezel-style or layer
  customization appears in source.
- **Padding**: Not set; this component applies no internal padding of its
  own.
- **Font**: Not set; font is never assigned, so the platform's default
  control font applies unmodified.
- **Background**: Not set; this component performs no drawing or layer
  coloring of its own.
- **Foreground/Text**: Not set; no title-color or styled-title
  customization appears in source.
- **Border**: Not set; no border or bezel customization appears in source.
- **Shadow**: Not set; no shadow customization appears in source.
- **Min/Max size**: Not set; the component adds no size constraints —
  `bounds` is read wherever it appears (cursor rect, hover-tracking region)
  but never written.

