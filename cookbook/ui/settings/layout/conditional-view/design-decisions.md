
**Decision**: Evaluate `isVisible` synchronously against the setting's
current value at the end of `init`, in addition to subscribing to future
changes through `UserSettingObserver.onChange`.
**Rationale**: without a synchronous initial evaluation, the view would
render in `NSView`'s default (visible) state until the observer's first,
asynchronously-delivered change notification arrived, producing a visible
flash of a `child` that should have opened hidden.
**Approved**: pending

**Decision**: Guard `applyVisibility` with `hidden != self.isHidden` before
writing `isHidden` or invoking `onVisibilityChange`.
**Rationale**: without the guard, a hosting `GroupView`'s separator/padding
recompute (`updateSeparators`) would run on every value the observed
setting publishes, even one that leaves this view's own visibility
unchanged, doing redundant layout work on every unrelated settings
interaction.
**Approved**: pending

**Decision**: (AppKit) Force a fatal error from both `init(coder:)` and the
frame-only `init(frame:)`, leaving the `observing:child:isVisible:`
initializer as the only usable one.
**Rationale**: `ConditionalView` has no meaningful default state — it cannot
decide a visibility without a `setting`, a `child`, and an `isVisible`
predicate — so both inherited `NSView` initializers that could construct
one without them are intentionally disabled rather than left to produce a
half-configured view.
**Approved**: pending

**Decision**: Conform to `SelfHidingSettingsView` and expose
`onVisibilityChange`, rather than keeping visibility purely internal to
the view.
**Rationale**: per the source's own doc comment, the callback is "told to
whoever placed this view — a group's card closes up over a row whose
content has taken itself off screen." The callback exists for a hosting
container's benefit, not for any need of `ConditionalView`'s own.
**Approved**: pending

