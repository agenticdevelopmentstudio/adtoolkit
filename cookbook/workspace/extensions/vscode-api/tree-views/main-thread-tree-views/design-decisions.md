
**Decision**: a row's handle is positional (`<parent>/<index>`) unless the extension declared a `TreeItem.id`, rather than always positional or always requiring a declared id.
**Rationale**: a positional handle is stable for a tree whose shape does not change between refreshes, which is what makes an expanded branch stay expanded across an ordinary refresh with no extra work from the extension. A tree that *reorders* its rows without declaring ids keeps the expansion on the position rather than the row — the exact astonishment upstream's own documentation warns extension authors about — but that cost falls on an extension that chose not to declare ids, not on one that did.
**Approved**: pending

**Decision**: `%` and `/` are escaped out of a declared id (`escapedForHandle`) rather than relying on the `#` prefix alone to separate the declared-id handle space from the positional one.
**Rationale**: a declared handle is a legal string-prefix of a positional one — a row declaring `id: "src"` gives its first unnamed child the handle `#src/0`, which is exactly what a row declaring `id: "src/0"` would be given without escaping. Escaping `/` (and `%` first, so the escape of `/` cannot itself be re-escaped) makes a declared handle contain no `/` at all, which is what makes the two spaces provably disjoint rather than merely unlikely to collide.
**Approved**: pending

**Decision**: a targeted refresh diffs the previous children against the newly reissued ones and forgets only the difference, rather than dropping the whole previous subtree before rebuilding it.
**Rationale**: this bridge's own history documents this as a fix for a real regression: dropping the whole subtree left every grandchild's row on screen with nothing behind it, because a targeted refresh (`onDidChangeTreeData(element)`) only reloads the one branch named, and the pane never re-asks a branch it has already read. Diffing keeps every row the extension did not stop naming answerable, at the cost of walking the previous-children list once per refresh.
**Approved**: pending

**Decision**: `activate(_:)` dispatches a row's command straight through `CommandRegistry.execute(id:arguments:)` rather than back through `vscode.commands.executeCommand`.
**Rationale**: a tree row routinely runs a command another extension, or the app itself, contributed — not necessarily one this extension registered — and the registry is the one place all three meet. Going back through `vscode.commands.executeCommand` would add a round trip through the extension's own runtime for no benefit, since the arguments are already in the right form, exactly what the commands bridge hands the registry itself.
**Approved**: pending

**Decision**: (AppKit/UIKit) every block installed on the JS-visible `TreeView` object captures `model` and `treeViews` only weakly and stores no `JSValue` of its own.
**Rationale**: a `JSValue` retained by an object JavaScriptCore itself holds (the `TreeView` object, exported back into the extension's context) is a retain cycle through `JSManagedValue.h`. The sole strong reference to a live `ExtensionTreeModel` is `MainThreadTreeViews.models`; dropping an entry from that dictionary is what makes every weakly-captured block on that model's `TreeView` object go inert at once, mirroring `MainThreadWebviews`'s identical no-capture contract.
**Approved**: pending

**Decision**: Two children requests for the same parent are not serialized by this bridge; the bookkeeping for a parent's previous children is taken at the start of the answer and not guarded against an overlapping request.
**Rationale**: `children(of:)` removes the parent's previous-children entry (`childHandles.removeValue`) before awaiting the provider's settlement, with no per-parent lock, generation counter or in-flight coalescing, so overlapping asks race on `childHandles`/`elements`. Closing it would take a per-parent in-flight task that a second ask joins or supersedes; the pane's own cache and 30-second budget (see the tree view) are what keep it from occurring today.
**Approved**: pending

