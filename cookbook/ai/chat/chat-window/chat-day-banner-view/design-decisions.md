
**Decision**: The date banner renders its text using `AIChatBubbleView.dayFormatter` rather than owning its own `DateFormatter`.
**Rationale**: Keeps the date shown at the top of each day consistent with whatever format the message-timestamp UI uses elsewhere in the chat transcript, and centralizes locale/calendar formatting policy in one place. This recipe therefore does not itself define the exact format pattern, locale rules, or calendar system used beyond the pattern `EEEE, MMMM d yyyy` — the only evidence available is the class's own doc-comment example, which itself misstates the weekday for June 3, 2026 as "Saturday" (June 3, 2026 is in fact a Wednesday); this recipe corrects the example to "Wednesday, June 3 2026" everywhere it is quoted.
**Approved**: pending**

**Decision**: The `day` value is normalized to `calendar.startOfDay(for:)` at construction time, rather than stored as the raw `Date` the caller passed in.
**Rationale**: Two messages posted at different times on the same calendar day must produce the same banner. Normalizing once at init — using an injectable `calendar` that defaults to `.current` — keeps the day-boundary decision testable, letting a test pin the time zone that decides which side of midnight an instant falls on, per the initializer's own doc comment.
**Approved**: pending**

**Decision**: The two rule lines are constrained to equal width to each other, rather than each being pinned with a fixed margin from the view's own edges.
**Rationale**: Keeps the date label on the view's horizontal center line regardless of how wide the formatted date string is — per the source comment, the rules are "equal to each other rather than each pinned to a margin, which is what keeps the date itself on the centre line whatever it says." No priority is set on this constraint pair, which is the source of the open question on **rule-width-priority** for very long date text.
**Approved**: pending**

**Decision**: Vertical spacing around the label is asymmetric — 16pt above, 8pt below.
**Rationale**: Per the source's doc comment, "the gap is what separates yesterday's last message from today's first, and it belongs to the break, not to the day it opens" — more space is reserved above the banner than below it so the visual break reads as belonging to the transition between days, not to the day being announced.
**Approved**: pending**

**Decision**: `init(coder:)` is marked `@available(*, unavailable)` and calls `fatalError()` if reached.
**Rationale**: The view is only ever meant to be constructed programmatically with a `day` (and optional `calendar`); Interface Builder/storyboard unarchiving has no way to supply those parameters, so the source forecloses that construction path entirely rather than leaving it partially working.
**Approved**: pending**

**Decision**: Rule width against a very long date is left to the layout system's default conflict resolution.
**Rationale**: No priority is set on the rule-width and gap constraints, so an over-long formatted date breaks an arbitrary required constraint; closing the gap takes either an explicit priority on those constraints or a guaranteed maximum width from the shared day formatter's output.
**Approved**: pending

