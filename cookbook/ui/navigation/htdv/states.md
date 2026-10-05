
Not applicable - this is the navigation, layout, and forms logic behind a
hierarchical topic detail view, not a visual component. The runtime state
machines it does own - the navigation controller's idle/loading/loaded/
error cycle and the form model's clean/dirty/saving/save-failed cycle - are
captured as requirements above (`is-loading-derivation`, `error-shape`,
`is-dirty-derivation`, `save-lifecycle`, `save-failure-preserves-dirty-
state`), not in a visual-state table.

