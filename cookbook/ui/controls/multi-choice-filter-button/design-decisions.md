
**Decision**: Close the menu on every pick rather than give menu items their
own checkbox views to keep the menu open across multiple picks.
**Rationale**: Per the source's own comment, this is "the stock behaviour of
a checkable menu, and the alternative — items hosting their own checkbox
views to keep the menu open — trades a familiar control for a hand-built
one." (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Identify choices by opaque string ids rather than a caller's
own enum.
**Rationale**: Per the source's own comment, this lets "one control serve any
caller's enum without this file knowing about it; callers map ids back to
their own type." (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Show the full selected list at one or two choices and switch to
a bare count at three or more.
**Rationale**: Per the source's own comment, "the summary title says what is
on without opening it, and 'Any' clears the whole set in one click" — the
count branch exists because, past two items, the full list stops fitting
in a glance. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Call `invalidateIntrinsicContentSize()` after every title
refresh.
**Rationale**: Per the source's own comment, "the title just changed length,
and the button's intrinsic width is measured from it — without this, a
longer summary lays out inside the old width and gets truncated ('Good
for: Cod…')." (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Leave the checkmark-resync operation unconditional on every
toggle/"Any"/selection-setting-operation call, while gating the
title-refresh operation and `onChange` behind `selection`'s `didSet`
equality check.
**Rationale**: This is the source's as-written, verified behavior: the
checkmark-resync operation is called directly from each method's body
regardless of whether the assignment above it actually changed
`selection`, while the title/`onChange` side effects live in `didSet` and
are naturally suppressed on a no-op assignment. Documented and required
here (see **reflects-checkmarks**) rather than smoothed into "both paths
react identically to a no-op." (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Do not deduplicate or reject `Choice` entries that share an
`id`.
**Rationale**: `selection` is a set of strings, and the checkmark-resync
operation matches menu items by their id, so two choices with the same id
are always kept in the same checked state as each other even though they
are visually distinct menu entries. The source enforces no uniqueness
constraint on `Choice.id`; keeping ids unique is a contract on the caller,
stated in Edge Cases. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: The button performs no contrast check: the foreground tint is the theme's primary text color and the bezel is the platform's, with no enforced ratio between them.
**Rationale**: Neither the tint nor the bezel is measured anywhere in the source. Closing the gap means auditing each shipped theme's foreground-versus-bezel contrast against a chosen accessibility bar (for example 4.5:1 for body-sized text), a call for the owner of the theme catalog.
**Approved**: pending

