
This module is the status board's one addition to the shared
configuration-status model. The model itself — the endpoint-status
classification, the project-status rollup, the pending-partition helper, and
the config-status result type — lives in the shared auto-configure engine,
the same classifier the backend runs behind `POST /auto-configure`. The
header comment says a second copy is "how the front page's banner and the
Config badges came to count different things in the first place", so this
module does not restate the classification rules.

What the module adds is the board's second way for an operator to say "leave
this monitor alone": a site's master monitoring switch (the editor's
"Monitoring enabled") being off. It folds that into the engine's single
opt-out flag at the boundary where the app's rows meet the engine's view of
an endpoint. It exports:

- the endpoint-like shape — the engine's own endpoint shape plus an optional
  monitoring-switch field.
- the opt-out fold — the fold itself, shared with the auto-configure
  adapter.
- the status operation — the engine's three-way classification of the
  folded endpoint.
- the unconfigured predicate — the boolean "should be wired but isn't, and
  not dismissed" predicate, derived from the wrapper above.

Use it wherever the board classifies an endpoint row (for example the sites
editor's config filter) instead of calling the engine's classifier on the raw
row.

