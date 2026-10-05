
- **Corner radius**: Not set by this component; the bar's rounded ends are
  the indicator's own default rendering — no custom drawing or
  corner-radius code appears in source.
- **Padding**: 0 — the progress indicator is pinned directly to all four
  edges of the view with no additional constant
  (**pins-progress-indicator-to-edges**).
- **Font**: Not applicable — the indicator draws no text of its own, and no
  font-related code appears in source.
- **Background**: Not set; the component performs no drawing or layer
  coloring of its own. The indicator's track color is the platform's
  default system appearance.
- **Foreground/Text**: Not applicable — no title or value text is rendered
  by the indicator or by the component itself.
- **Border**: Not set; no border customization appears anywhere in source.
- **Shadow**: Not set; no shadow customization appears anywhere in source.
- **Min/Max size**: Not set via any explicit width/height constraint on the
  view. The indicator's size equals the view's bounds exactly, via
  required-priority equal constraints on all four edges
  (**pins-progress-indicator-to-edges**), so the view has no intrinsic size
  floor or ceiling of its own — its size is whatever the caller's row
  layout gives it. The regular control size gives the indicator its own
  natural bar height as an intrinsic content size; if the container the
  view is placed in is shorter than that height, the required edge-pinning
  constraints can conflict with the indicator's own vertical content-size
  constraints at layout time. The source neither guards against nor
  documents this case.

