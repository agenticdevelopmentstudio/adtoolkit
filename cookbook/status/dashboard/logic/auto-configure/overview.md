
This adapter is the status dashboard's client-side entry point into "Auto
Configure". It does no matching of its own: the planner, classifier, and
runner belong to the shared auto-configure engine, the same logic the backend
runs behind `POST /auto-configure`. The reason is explained directly: a
second, hand-written copy of the planner risked canonicalizing a host
differently on each side, filing the same project under different sites
depending on which side acted.

This adapter provides three things: a port adapter that maps the
monitoring-configuration client onto the engine's port contract; a match
operation that runs the engine match-only (it never asks it to create) and
flattens the result into the match-result shape a dialog renders; and a pair
of detail-block builders that build the "Left alone:" and "Also:" text blocks
appended to the engine's own summary sentence, each capped at a fixed number
of named projects.

Callers: a per-platform project panel calls the match operation for its
"Match" and "Match all" actions. A global summary panel appends the note and
skip detail blocks to the backend-driven global "Auto Configure" summary. Site
creation stays on the backend, because only the backend sees every site in one
transaction-scoped snapshot.

