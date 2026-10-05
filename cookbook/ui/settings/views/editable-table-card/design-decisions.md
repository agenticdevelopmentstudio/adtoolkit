
**Decision**: Rejected edits are reported to the owner and the row snaps back, with no message shown by the card.
**Rationale**: Keeps the card free of dialogs; the owner decides whether to tell the user, at the cost of silent reversion when it does not.
**Approved**: pending

**Decision**: A reload during an edit is held and not merged field by field.
**Rationale**: Replacing the table under a live field would drop typed text; holding is simple and safe, at the cost of stale data on screen until the edit ends.
**Approved**: pending

**Decision**: The card parses day, time, duration and money text itself.
**Rationale**: Keeps callers from repeating parsing and range checks; the cost is that the card depends on the formatters and is larger than a pure rendering view, so separation of concerns is only partial.
**Approved**: pending

**Decision**: Sorting is reported, not performed.
**Rationale**: Lets the owner sort by its own rules and keep ids stable; the card cannot show a sort indicator without the owner updating it.
**Approved**: pending

