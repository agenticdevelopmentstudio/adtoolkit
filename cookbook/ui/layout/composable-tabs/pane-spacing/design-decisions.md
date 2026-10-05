
**Decision**: `PaneSplitView.dividerThickness` reads `PaneSpacing.current` — a fresh settings-store read — on every call rather than caching the gutter value on the instance.
**Rationale**: `dividerThickness` is a computed property with no invalidation hook of its own, and `spacingDidChange()`'s entire purpose is to force AppKit to re-ask this property after a setting changes; a cached value would go stale the moment either gutter setting changed and defeat that mechanism.
**Approved**: pending

**Decision**: `spacingDidChange()` forces a relayout by toggling `dividerStyle` to a different value and back, rather than calling an invalidation method such as `needsLayout`.
**Rationale**: the source comment explains that an `NSSplitViewController` lays its panes out with constraints built from `dividerThickness` at the moment items were installed, and only re-assigning `dividerStyle` is documented to make AppKit discard and re-ask for those constants.
**Approved**: pending

**Decision**: the two gutter settings default to `1` point (a hairline) while the four edge insets default to `0`.
**Rationale**: the source comment states this preserves the pre-existing hairline divider appearance so introducing the setting does not visibly re-space any window on the update that adds it, while frame insets start at `0` because the gap around panes is an opt-in look, not the prior house style.
**Approved**: pending

**Decision**: spacing is a single app-wide set of settings, not a per-window or per-project value.
**Rationale**: the source comment states that a window whose panes are spaced differently from the window beside it reads as a bug, and per-window spacing would have to be carried in every saved layout to survive a relaunch.
**Approved**: pending

**Decision**: `minimumDividerGrab` is a fixed `6` points regardless of the configured gutter thickness, including when the gutter is `0`.
**Rationale**: the source comment states a zero-point gutter is a legitimate look, and without a wider hit-test allowance it would be a layout the user cannot undo with the mouse; the value `6` itself is not derived from a cited platform minimum.
**Approved**: pending

**Decision**: `PaneSpacing` does not clamp or validate any of the six stored settings; range validation on a negative or implausibly large value is the settings-control layer's responsibility, not `PaneSpacing.current`'s.
**Rationale**: `PaneSpacing.current` builds its `Spacing` by assigning each setting's raw `value` straight into the edge/gutter subscript, never through `Spacing.setting(_:to:in:)` or `Spacing.adjusting(_:by:in:)` — the two methods that actually call `Int.clamped(to:)`. Those methods exist for, and are used by, the settings-control layer that presents the editable control; `PaneSpacing` itself is a thin passthrough with no comparable seam, so clamping lives where the value is entered, not where it is read back.
**Approved**: pending

