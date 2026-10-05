
**Decision**: (AppKit) The frame-accepting initializer discards its
argument and always constructs with a zero frame.
**Rationale**: The component positions itself entirely through Auto
Layout (disabling autoresizing-mask/frame translation, plus the activated
edge-pinning constraints). The inherited frame-based initializer exists
only so the type can still be constructed through it at all; the source
ignores the caller-supplied rect rather than reconciling it with the Auto
Layout constraints that take over immediately afterward. This is the same
pattern used by the sibling horizontal stack view and divider components,
so a port SHOULD keep discarding the caller's rect for parity with those
siblings rather than reconcile it with the constraints that immediately
override it.
**Approved**: pending

**Decision**: (AppKit) The internal stack view is exposed publicly, unlike
the otherwise structurally identical horizontal stack view, whose
internal stack view is private.
**Rationale**: Not explained in source comments. This is a genuine
asymmetry between the two sibling wrappers: a caller of this component
can reach the internal stack view to reconfigure it (e.g. alignment or
distribution) or to remove an arranged subview directly, while a caller
of the horizontal sibling cannot. Recorded here rather than smoothed
over, since the two types would otherwise read as interchangeable except
for orientation.
**Approved**: pending

**Decision**: The add-arranged-view operation is the only mutation method
the component defines; no counterpart operation for removing an arranged
subview is exposed (though, unlike the horizontal sibling, the public
internal-stack-view property gives a caller an indirect path to one).
**Rationale**: Not explained in source comments. This is consistent with
the broader pattern of assembling a settings row or panel once, at
construction time, rather than mutating it afterward. Recorded here as a
known limitation of the public method surface rather than an intended,
documented contract, since nothing in the source states it was
deliberate.
**Approved**: pending

