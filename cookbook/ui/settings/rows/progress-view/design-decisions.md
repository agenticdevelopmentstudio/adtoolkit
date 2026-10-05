
**Decision**: This component never reads the view model's title or
explanation (both inherited from the base view model), unlike every other
row in this same family (the checkbox row, the text edit row, the color
picker row, the stepper row, and others), which all build a label from the
view model's title.
**Rationale**: Not explained anywhere in source (AppKit/UIKit) — no
comment addresses why the title and explanation the view model carries go
unused. This recipe records the deviation from sibling views rather than
assuming a row-composition convention (e.g. that a caller always pairs
this component with a separate label or an explanation row) that the given
source does not itself show.
**Approved**: pending

**Decision**: The initial progress value is applied twice at construction
— once implicitly, because the view model's progress subscription
delivers the current value synchronously to a new subscriber (AppKit/UIKit
source: a `@Published` publisher, `viewModel.$progress.sink`), and once
explicitly via a direct call immediately after that subscription is set
up (AppKit/UIKit source: `self.apply(progress: viewModel.progress)`).
**Rationale**: This produces no observable difference (the same value is
applied twice in a row, both before construction returns), but it is
present in source as written; this recipe records it rather than silently
simplifying it away. No comment in source explains whether the explicit
call is defensive redundancy or an oversight.
**Approved**: pending

**Decision**: The indicator's minimum/maximum values are never set by
this component, leaving the indicator's default 0–100 range in effect;
the view model's progress doc comment states only that a present value
"drives a determinate bar (consumer chooses the scale)."
**Rationale**: Because the scale is left at the default range and the
indicator is exposed publicly, a caller wanting a different scale must
reach through the public progress-indicator property and set the
minimum/maximum values directly — neither this component nor its view
model provides a dedicated API for it.
**Approved**: pending

**Decision**: The frame-based initializer's fatal-error message
(AppKit/UIKit source: `init(frame frameRect: NSRect)`) is the literal
string `init(frame frameRect: NSRect`, missing a closing parenthesis, and
does not follow the sentence form of the sibling coder-initializer
message.
**Rationale**: documented here as a source quirk rather than corrected,
for the same reason sibling recipes in this file family record it: it
reads as a truncated fragment of the initializer's own signature, very
likely a typo, but the source is unchanged for this recipe.
**Approved**: pending

**Decision**: The indicator's edges are pinned to the view's edges with
required-priority equal constraints rather than offering a placement
choice the way the button row offers fill/leading/centered placement.
**Rationale**: This component has exactly one placement — full-bleed —
with no choice offered as an alternative. This recipe records that as a
genuine difference in scope from the button row, not an oversight; the
source gives it no other placement to describe.
**Approved**: pending

