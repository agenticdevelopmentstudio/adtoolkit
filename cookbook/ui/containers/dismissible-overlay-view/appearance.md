
- **Corner radius**: None — the source sets no corner radius on either
  itself or the backdrop.
- **Padding**: None — presenting the overlay constrains all four of its
  edges equal (not inset) to the corresponding host edges.
- **Font**: Not applicable — this base view renders no text of its own; any
  text belongs to whatever content a subclass adds above the backdrop.
- **Background**: A blurred backdrop view with a caller-selectable
  material (default: the platform's hud-style material), a within-window
  blending behavior, and an active (not inactive) appearance state.
- **Foreground/Text**: Not applicable — no label or text-rendering view
  exists in the source.
- **Border**: None — no border is configured on the view or the backdrop.
- **Shadow**: None — no shadow-related layer property is set anywhere in
  source.
- **Min/Max size**: None declared. The overlay has no intrinsic size of its
  own; presenting it pins all four edges to exactly fill the host.

