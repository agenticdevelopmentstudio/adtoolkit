
Not applicable: this component's only user-facing strings are the operator-
facing skip/conflict/note reasons and the summary sentences returned by
`summarizeAutoConfigure` and `manualDetail` (e.g. `"that domain is already
wired to ${x}"`, `"Matched 1 project to its site."`) — these are hardcoded
English string literals with no localization mechanism in any of the given
sources; a port MUST decide whether/how to localize them, since the source
itself never does.

