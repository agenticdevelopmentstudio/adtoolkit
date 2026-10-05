
**Decision**: (AppKit) `init(frame frameRect: NSRect)` discards its `frameRect` argument and always calls `super.init(frame: .zero)`.
**Rationale**: `DividerView` positions itself entirely through Auto Layout (`translatesAutoresizingMaskIntoConstraints = false` plus the activated height constraint). The inherited frame-based initializer exists only so `DividerView` can still be constructed through it at all; the source ignores the caller-supplied rect rather than reconciling it with the Auto Layout constraints that take over immediately afterward.
**Approved**: pending

**Decision**: (AppKit) The divider color is applied through two independent paths — once via `ThemePaletteObserver`'s notification-driven callback, and again via an `updateLayer()` override that re-reads `resolvedThemeScope.palette.dividerColor` on every AppKit-triggered layer update.
**Rationale**: Not explained in source comments; there are none on this override. The two paths are not mutually exclusive — `updateLayer()` covers any AppKit-invoked layer refresh that does not route through either of `ThemePaletteObserver`'s two notifications, at the cost of reassigning `backgroundColor` a second time on paths that do overlap (e.g. a theme change that also triggers `updateLayer()`). This redundancy is real technical debt in the source, recorded here rather than smoothed into a single described path; the Behavioral Requirements therefore require only the notification-driven repaint paths, so a port is not obligated to reproduce the redundancy.
**Approved**: pending

**Decision**: `SettingsLayout.default[.dividerThickness]` is read exactly once, into an `NSLayoutConstraint` activated at `init` time, even though `SettingsLayout` is `Observable`/`@Published`.
**Rationale**: Not explained in source comments. `DividerView` never subscribes to `SettingsLayout.default`'s publisher, so an existing `DividerView` does not resize if that value is later changed at runtime (see **ignores-settings-layout-changes** and Edge Cases → Boundary values). Recorded here as a known staleness limitation rather than an intended contract, since nothing in the source suggests it was deliberate.
**Approved**: pending

