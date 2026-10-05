
The Panel Heading View renders a heading over a *run* of groups, one level
above a single group's own caption — distinct from the Group View's own
header, which captions a single list of rows rather than a run of groups.
It pairs a title label (styled as a primary-emphasis heading) with an
optional caption, which — when supplied — is wrapped in the Explanation
View rather than a label of its own, so it wraps by the one policy every
settings blurb in this system shares instead of a copy of it (see the
Explanation View recipe). Use it above a panel whose groups fall into more
than one kind that a reader needs to see distinguished up front — for
example, a Key Commands panel's per-window cards, split by whether a
window's commands fire only in that app or everywhere. The one call site
that constructs a Panel Heading View, a panel's own add-heading operation,
is not part of this recipe's source; its own spacing decision is recorded
in Design Decisions, not here.

