
- **Corner radius**: None; the component is not given a compositing
  layer or a corner radius of its own.
- **Padding**: None of its own. The internal stack view is pinned flush
  to all four edges of the component with zero additional inset (see
  **pins-stack-view-to-container-edges**); the only spacing the component
  introduces is the gap between arranged subviews set from the standard
  group-spacing value (see **sets-arranged-subview-spacing-from-group-spacing-token**).
- **Font**: Not applicable — the component renders no text or other
  font-dependent content of its own.
- **Background**: None; the component paints no background color of its
  own — it is fully transparent, showing whatever sits behind it.
- **Foreground/Text**: Not applicable — the component has no text or
  foreground content; it only positions its arranged subviews.
- **Border**: None; the component draws no border of its own.
- **Shadow**: None; the component draws no shadow of its own.
- **Min/Max size**: No explicit min/max width or height constraints of
  its own. Because the internal stack view is pinned flush to all four
  edges with zero inset, the component's size is driven entirely by its
  arranged subviews' natural content sizes plus the inter-item spacing
  (see **sets-arranged-subview-spacing-from-group-spacing-token**).

