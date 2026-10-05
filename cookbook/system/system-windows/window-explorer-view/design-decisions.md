
**Decision**: Prune stale ids from `selectedWindowIDs` after a scan only when
`activeGroupID == nil`; never prune when it is non-nil.
**Rationale**: in discovery mode the binding represents "windows currently
checked on screen," so an id for a window that vanished (closed, minimized,
now off-screen) is meaningless and MUST be dropped; in direct-assignment
mode the same binding instead represents persistent group membership, and a
member window that is merely not visible in *this* scan (e.g., a different
space, temporarily hidden) MUST NOT be silently unassigned from the group —
per the source comment directly above the prune.
**Approved**: pending

**Decision**: (SwiftUI) Fall back to the hard-coded `Color.blue` for a context badge when
`Color(hex: ctx.color)` returns `nil`, rather than a theme color.
**Rationale**: `Color(hex:)` returns `nil` only when the stored string is not a
valid 6-digit hex value, which should not occur for a color a context
stores through the app's own color picker; the fallback is a defensive
default for malformed data rather than an expected runtime path, which is
why it is a fixed system color rather than something drawn from the theme
palette.
**Approved**: pending

