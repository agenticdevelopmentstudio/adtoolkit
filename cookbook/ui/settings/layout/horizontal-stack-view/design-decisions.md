
**Decision**: (AppKit) `init(frame frameRect: NSRect)` discards its
`frameRect` argument and always calls `super.init(frame: .zero)`.
**Rationale**: The component positions itself entirely through Auto Layout (`translatesAutoresizingMaskIntoConstraints = false` plus the activated edge-pinning constraints). The inherited frame-based initializer exists only so the type can still be constructed through it at all; the source ignores the caller-supplied rect rather than reconciling it with the Auto Layout constraints that take over immediately afterward. This is the same pattern used by the sibling `VerticalStackView` and `DividerView`.
**Approved**: pending

**Decision**: The add-view operation is the only public mutation entry
point; no counterpart for removing an arranged child is exposed.
**Rationale**: Not explained in source comments. This is consistent with the ComposableSettingsWindow pattern of assembling a settings row or panel once, at construction time, rather than mutating it afterward. Recorded here as a known limitation of the public API rather than an intended, documented contract, since nothing in the source states it was deliberate.
**Approved**: pending

**Decision**: (AppKit) `stackView` is declared `private`, unlike the
otherwise structurally identical `VerticalStackView`, whose `stackView`
property is `public`.
**Rationale**: Not explained in source comments. This is a genuine asymmetry between the two sibling wrappers: a caller of `HorizontalStackView` cannot reach the internal `NSStackView` to reconfigure it (e.g. alignment or distribution) or to remove an arranged subview directly, while a caller of `VerticalStackView` can. Recorded here rather than smoothed over, since the two types would otherwise read as interchangeable except for orientation.
**Approved**: pending

