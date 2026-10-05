
**Decision**: Placements are stored per screen set and replay an absolute top-left offset on an exact screen match.
**Rationale**: Per the `WindowPlacement` and class doc comments, replaying the literal offset means content-driven resizes "can never walk the window between launches", which the old proportional scheme did (`testContentRefitCannotDriftTopLeftAcrossRelaunches` records a clamped `proportionalY` of 1.1).
**Approved**: pending

**Decision**: A relative travel-fraction position is saved alongside the offset and used only on a non-exact match or an unknown set.
**Rationale**: A resolution change or a never-seen location makes the absolute offset meaningless; the relative position keeps a window flush to the same corner or centered.
**Approved**: pending

**Decision**: `minSize` wins over the screen size in every sizing path (`clampedLength`).
**Rationale**: Per the `clampedLength` doc comment, four paths used to spell this rule differently and returned different sizes for the same window; collapsing below `minSize` breaks the promise `minSize` makes, so the window overhangs instead.
**Approved**: pending

**Decision**: `contentHuggingFrame` chooses anchors once per gesture and returns them for the caller to pass back.
**Rationale**: Per its doc comment, no stateless nearest-edge rule is reversible under both a start and an end anchor; holding the anchor for the gesture makes "the move out the move back" (wfm-012, wfm-013).
**Approved**: pending

**Decision**: Save and restore call `ScreenManager.touchCurrentSet()` before reading `currentSetID`.
**Rationale**: AppKit repositions windows during a display reconfiguration and the resulting `windowDidMove` can reach `saveFrame` before the screen-change notification, which would otherwise file the placement under the outgoing set.
**Approved**: pending

**Decision**: A non-exact restore re-saves immediately.
**Rationale**: The delegate hooks are not wired during window loading, so without an explicit save the stale fingerprint would force relative placement on every launch instead of reaching the exact fast path.
**Approved**: pending

**Decision**: Per-window state is cached in memory, write-through.
**Rationale**: `saveFrame` fires on every move/resize tick; the cache avoids a `UserDefaults` read and JSON decode each time, under the documented sole-writer precondition.
**Approved**: pending

**Decision**: Placements are pruned with the same rule `ScreenManager` uses for sets, plus a recency grace period.
**Rationale**: Per the `saveFrame` comment, a placement survives while its set is known or it was saved recently, "so a rebuilt set list can't wipe other locations' state".
**Approved**: pending

**Decision**: Geometric centering is implemented by hand instead of `NSWindow.center()`.
**Rationale**: Per the `applyGeometricCenter` comment, `center()` places the window one-third from the top, not at the geometric center; `center()` is kept only as the no-screen fallback.
**Approved**: pending

**Decision**: v1 state is decoded through a fallback path and migrated on first restore; unrecognised blobs degrade to empty state.
**Rationale**: Per the `PersistedWindowState` decoder comment, degrading rather than throwing makes every decode call site start fresh instead of failing.
**Approved**: pending

**Decision**: `bestScreen` falls back to AppKit's window screen and main screen rather than the injected provider.
**Rationale**: This is the source's behavior when the window intersects no provided screen; it means tests with mock screens and an off-screen window can receive a real `NSScreen`. Recorded as a known quirk, not a chosen rule.
**Approved**: pending

**Decision**: Window-state storage load and save failures are absorbed without a log or a signal to the window frame manager.
**Rationale**: `UserDefaultsWindowStateStorage` decodes with `try?` and returns nil on failure and skips a write when `try?` encoding fails, `SettingsStoreWindowStateStorage` delegates to a settings store with the same absorbing behavior, and `WindowFrameManager` logs only placement events. Closing it means deciding whether failures are logged or surfaced and then widening the `WindowStateStorage` protocol.
**Approved**: pending

