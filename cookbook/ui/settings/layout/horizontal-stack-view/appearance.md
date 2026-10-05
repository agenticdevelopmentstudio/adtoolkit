
- **Corner radius**: None; the component has no layer or shape of its own.
- **Padding**: None of its own. The internal stack view is pinned flush to
  all four edges of the component with zero additional inset (see
  **pins-stack-view-to-container-edges**); the only spacing the component
  introduces is the group-spacing gap between arranged children (see
  **group-spacing**).
- **Font**: Not applicable — the component renders no text or other
  font-dependent content of its own.
- **Background**: None; the component sets no fill of its own — it is
  fully transparent, showing whatever sits behind it.
- **Foreground/Text**: Not applicable — the component has no text or
  foreground content; it only positions its arranged children.
- **Border**: None; the component draws no border of its own.
- **Shadow**: None; the component sets no shadow of its own.
- **Min/Max size**: No explicit min/max width or height constraints of its
  own. Because the internal stack view is pinned flush to all four edges
  with zero inset, the component's size is driven entirely by its arranged
  children's intrinsic content sizes plus the group-spacing gap between
  them (see **group-spacing**).

