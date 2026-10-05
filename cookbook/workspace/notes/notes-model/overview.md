
This is the model, persistence-contract, and orchestration layer behind
the Notes feature:
a local, on-device notes store with no UI of its own. A note is an
immutable-id value whose title and excerpt are always derived from its
markdown content, never stored. A note folder is the tree shape a folders
pane displays, built from a flat category/edge read. The storage contract
is the abstract, four-operation persistence seam the manager depends on,
required to be safe to call from multiple threads; the markdown-backed
conformer is the concrete implementation that maps a note onto a
markdown-store document, and is also the layer that owns the entire
frontmatter-ownership contract for the one key it writes, `pinned`. The
manager is the object, confined to the primary UI thread, that owns the
in-memory list of notes, issues every storage call off that thread in
strict issue order, runs a per-note debounced autosave, and surfaces a
failed read or write as a single failure record.

This is a different, unrelated contract from the web-side notes client —
its notes are a backend content
resource reached over a REST API, these are a local, on-device store
reached through the storage contract described here, and the shared name
is a coincidence, not a shared contract.

