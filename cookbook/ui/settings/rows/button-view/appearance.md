
- **Corner radius**: Not set by the component; governed entirely by the
  button's default bezel style — no custom shape or layer customization
  appears in source.
- **Padding**: Not set; the component applies no internal padding around
  the button. Any inset between the button's content and its own edge is
  the platform button's unmodified default.
- **Font**: Not set; the button's font is never assigned, so the
  platform's default control font applies.
- **Background**: Not set; the component performs no drawing or layer
  coloring of its own.
- **Foreground/Text**: Not set; no custom title-color or tint
  customization appears in source, so the button's default title color
  applies.
- **Border**: Not set; no border or bezel customization appears in
  source.
- **Shadow**: Not set; no shadow customization appears in source.
- **Min/Max size**: Not set via explicit width/height constraints. In
  fill, the button's size equals the component's bounds. In
  leading/centered, the button's height equals the component's height
  (top and bottom pinned); its width is bounded by the trailing cap (and,
  for centered, the leading floor) but not fixed — the final width is the
  button's own intrinsic content size for its title, constrained not to
  exceed the component.

