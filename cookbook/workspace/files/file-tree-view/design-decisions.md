
**Decision**: On Apple platforms, use `NSOutlineView` rather than a SwiftUI
`List` for the tree.
**Rationale**: a SwiftUI list row's tap gesture attached to the row's content
never fires, and a directory's row, being a disclosure-group label, is not
something a `List` will select at all — half the tree answered a click with
nothing. `NSOutlineView` selects on mouse-down for every row it draws, which
is the behavior this component needs.
**Approved**: pending.

**Decision**: Use `children == nil` for a leaf, a package, *and* a directory
that was read and found empty — rather than reserving `nil` for leaves
only — and disambiguate the "was this a directory?" question downstream in
the open-if-file operation via a check of "not a directory, or is a
package," not via the children value itself.
**Rationale**: a node deliberately sets `children = nil` (not `[]`) for a
directory that reads empty, so the outline reads an empty array as
"expandable, not yet read" — keeping `[]` would leave a disclosure triangle
that opens onto nothing. The open-if-file operation's own guard is what then
stops a double-click or single-click on that now-leaf-shaped empty directory
from being sent to the document viewer as if it were a file.
**Approved**: pending.

**Decision**: Cache path→row lookups lazily, in an index built on demand, and
verify a cache hit against the row's actual content before trusting it,
rather than either always scanning or always trusting the cache.
**Rationale**: this component observes the document store, so every
keystroke in *any* open document, in *every* open file browser, used to cost
an O(rows) path-string scan; the verify-before-trust step exists because a
stale hit would otherwise silently redraw or reselect the wrong file rather
than fail loudly.
**Approved**: pending.

**Decision**: On Apple platforms, use two independent guard flags,
`isSyncingSelection` and `isSyncingExpansion`, rather than a single "the
controller is currently driving the outline" flag.
**Rationale**: each guards a different feedback loop — `isSyncingSelection`
stops a model-driven selection change from being reported back through
`outlineViewSelectionDidChange`, and `isSyncingExpansion` stops a
restoration- or reveal-driven expand/collapse from being reported back
through `outlineViewItemDidExpand`/`outlineViewItemDidCollapse` — and the two
kinds of programmatic change do not always happen together (restoring
disclosure without touching selection, or vice versa).
**Approved**: pending.

**Decision**: The reveal and clear-reveal operations write
`selection.selectedNode` and `selection.selectedRoot` directly instead of
relying on the outline's own selection-change notification to record the
change.
**Rationale**: "the highlight" and "the selection" are distinct — the
notification is deliberately suppressed while a reveal is being applied (so
a reveal is not echoed to whatever editor pane it came from), which would
otherwise leave `selection` naming a stale file and `selectedRoot` pointing
at the wrong project root. On Apple platforms this suppression is the
`isSyncingSelection` guard flag (see Platform Notes).
**Approved**: pending.

**Decision**: Restore a deeply nested expanded/selected path incrementally,
across as many reloads as the depth requires, rather than requiring the
whole path to already be drawn.
**Rationale**: expanding a directory only *starts* an asynchronous read of its
contents; the loop terminates naturally because a pass that expands nothing
triggers no further reload, so a fixed-depth single pass would leave
anything below the first unread level permanently unrestored.
**Approved**: pending.

**Decision**: Leave `selection.selectedRoot`/orphaned-selection cleanup, when
a root disappears entirely, to the hosting file browser rather than handling
it in this component.
**Rationale**: this component's own reselection logic only clears
`selection.selectedNode` when the outgoing selection was a node; a selected
root *header* (a root manager) that disappears from a reload is not cleared
here. The [File Browser](adtoolkit://cookbook/workspace/files/file-browser-view)'s
own `teardown-clears-orphaned-root-selection` requirement is what actually
guarantees `selection.selectedRoot` is cleared when its root is removed.
**Approved**: pending.

