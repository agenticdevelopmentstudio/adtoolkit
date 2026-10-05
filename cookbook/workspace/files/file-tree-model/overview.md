
This is a **logic** component — no visual surface — the file tree's model
layer, made up of four parts: a configuration value (a passive, immutable
set of options), a tree node (representing one file or directory), a
file-system watcher (a thin wrapper around the platform's native
file-change notifications), and a coordinator (the state holder that owns
the tree and drives the watcher). The coordinator's own doc comment states
its purpose directly: it "encapsulates the sync -> watch -> surgical-update
lifecycle. All filesystem I/O runs on background [threads] to avoid
blocking the UI, and a sync reads one level: the root's own entries.
Everything below that is read when it is shown." Concretely: a full sync
reads only the root directory's immediate entries and either replaces or
merges them into whatever tree is already published; starting to watch
opens a change-notification stream scoped to the root and, on every batch
of changes, re-reads just the affected directories and merges the results
in; a node's lazy children-load operation gives any node the same
one-level, read-on-demand behavior when a caller (typically a tree view)
expands it. The merge operation is the mechanism every one of these paths
funnels through to keep already-materialized node objects (and therefore
their own already-read children, and anything a tree view is holding a
reference to) alive across a re-sync rather than being silently replaced by
structurally-equal-but-distinct objects. The direct consumer of this model
is a file tree manager (out of scope for this recipe), which in turn feeds
the file tree view — see
[File Tree View](adtoolkit://cookbook/workspace/files/file-tree-view)
and
[File Browser](adtoolkit://cookbook/workspace/files/file-browser-view)
for how this model's `nil`-vs-empty-array `children` distinction and its
swallowed directory-read failures are consumed one layer up.

