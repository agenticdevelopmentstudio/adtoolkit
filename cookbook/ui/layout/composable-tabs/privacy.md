
- **Data collected**: None by this component itself. It manages an in-memory
  tree of node ids, view identifiers, and sizing fractions describing *how*
  panes are arranged — never the content displayed inside a pane.
- **Storage**: In-memory only, for the life of the tree (its children,
  thickness fractions, zoomed leaf, and related state). Whether and how a
  snapshot handed to the layout-change callback is written to disk is
  entirely the host's responsibility and outside this file's source.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source.
- **Retention**: None beyond the component's own lifetime; state is
  discarded when the tab/tree is torn down.

