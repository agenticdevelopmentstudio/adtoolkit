
**Decision**: Show the current value in a separate, monospaced value
label rather than relying on the stepper to display it.
**Rationale**: The stepper renders only its up/down arrow control and
carries no visible number of its own; pairing it with a dedicated value
label, kept in sync on every change, makes the current count visible
without requiring a user to press or focus the stepper.
**Approved**: pending

**Decision**: Fix the stepper's increment at `1` regardless of the view
model's range.
**Rationale**: Per the source's own doc comment, this component targets
"small bounded counts (recents, retry limits, etc.)" where each click
should move by the smallest meaningful unit; the type is generic only
over the bound, not the step size, so a caller with a wide range gets
the same one-at-a-time increments as a caller with a narrow one.
**Approved**: pending

**Decision**: Set the value label's horizontal content compression
resistance to required while leaving the label and the stepper at their
default priorities.
**Rationale**: In a tight row, the row layout shrinks the
lowest-resistance view first; a required floor on the value label keeps
the numeric value — the one piece of information the row cannot afford
to truncate — from being the view that gives way before the title label
does.
**Approved**: pending

**Decision**: Disable wraparound on the stepper (AppKit/UIKit source:
`stepper.valueWraps = false`).
**Rationale**: For a bounded count like a retry limit, wrapping from the
maximum back to the minimum (or the reverse) on one more click would
silently jump the setting to the opposite end of its range; disabling
wrap keeps a repeated click at a bound a no-op instead.
**Approved**: pending

**Decision**: Forward the view model's minValue/maxValue straight to
the stepper's minimum/maximum with no validation, reordering, or
clamping when the range is inverted (minValue > maxValue).
**Rationale**: Callers MUST supply minValue <= maxValue; the range view
model is expected to guarantee an ordered range at construction, so this
component does not duplicate that check. An inverted range that reaches
this component falls through to the stepper's own unspecified handling
rather than being coerced or clamped here (contrast the integer field
row, which explicitly detects and skips clamping on this case).
**Approved**: pending

**Decision**: Unconditionally assign the component's own handler to the
view model's change-notification callback in the initializer, replacing
any handler already registered on that view model instance (see
replaces-view-model-onchange).
**Rationale**: The component owns keeping its three subviews in sync
with the view model's current state; a single-owner change-notification
handler is the simplest way to guarantee the sync runs on every external
change, at the cost of the component being incompatible with a caller
that also wants to observe the same view model instance directly — the
same trade-off the checkbox row and the integer field row make.
**Approved**: pending

**Decision**: The component performs no contrast check of its own: the label's primary-text color and the value label's secondary-text color resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
**Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
**Approved**: pending

