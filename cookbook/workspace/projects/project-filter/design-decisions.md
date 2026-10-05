
**Decision**: `matches(_:query:)` and every row-highlighting caller derive
their answer from the same `ranges(of:in:)` computation rather than each
implementing its own substring search.
**Rationale**: Per the source's top-of-file doc comment, this keeps "the
characters a row highlights" from ever disagreeing "with the reason that row
survived the filter" — the source's own name for this is `dry`. A second,
independently-written search (even one intended to behave identically) would
be free to drift from this one over time.
**Approved**: pending

**Decision**: the scan in `ranges(of:in:)` advances by `max(match.length, 1)`
rather than by `match.length` alone.
**Rationale**: The source comment explains this guards against a query whose
match has zero length leaving `start` unchanged, which would loop forever;
with only the `.caseInsensitive` option in use, a non-empty query is not
expected to ever produce a zero-length match, but the guard makes the loop's
termination (`ranges-loop-terminates`) hold regardless. The same advance rule
produces the non-overlapping scan behavior in `non-overlapping-scan-advance`
as a side effect, not as its primary purpose.
**Approved**: pending

**Decision**: `ranges(of:in:)` searches with `.caseInsensitive` only, never
`.regularExpression`.
**Rationale**: The component's purpose is matching what a user typed against
a project's name and path; treating a query literally means a user who types
a period, a bracket, or an asterisk while searching for a real file or folder
name gets a search for that literal character, not a broken or
surprising pattern match.
**Approved**: pending

