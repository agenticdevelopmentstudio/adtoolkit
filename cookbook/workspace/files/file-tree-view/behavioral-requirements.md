
- **top-level-rows-are-managers**: The outline's top-level rows MUST be
  exactly `roots.managers`, one row per root manager, in the order that
  array supplies.
- **child-ordering-directories-first**: Rows for a directory's contents MUST
  list subdirectories before files, each group sorted alphabetically and
  case-insensitively (inherited from the tree model's directory-read
  ordering).
- **hidden-file-visibility**: Rows MUST include hidden
  (dot-prefixed) files and directories, but MUST NOT include a `.DS_Store`
  entry (inherited from the tree model's directory-read behavior).
- **empty-root-placeholder-text**: A root manager with no children currently
  loaded MUST render a single placeholder row reading "Scanning…" while
  `manager.isSyncing` is `true`, or "Empty" otherwise.
- **placeholder-not-selectable**: A placeholder row MUST NOT be selectable.
- **unread-directory-shows-triangle**: A directory whose contents have not yet
  been read (`children == []`) MUST be reported expandable, so its disclosure
  triangle appears before anything is known to be inside it.
- **leaf-hides-triangle**: A file, a package, or a directory whose read
  completed with nothing inside (`children == nil`) MUST NOT be reported
  expandable.
- **expand-loads-children-lazily**: Expanding a directory row MUST trigger
  the lazy children-load operation on its node, which starts an asynchronous
  read of that one directory's contents.
- **expand-watches-children-publisher**: Expanding a directory row MUST begin
  watching that node's `children` for updates (the children-watch operation)
  so the rows update once the read finishes.
- **children-arrival-reloads-subtree-only**: When a watched directory's
  children publish a new value, only that item's row and subtree MUST be
  reloaded (the subtree-reload operation); the rest of the outline MUST NOT
  be reloaded.
- **children-arrival-preserves-expansion-and-selection**: A subtree reload
  triggered by arriving children MUST re-expand the item if it was expanded
  immediately beforehand, and MUST restore whichever row was selected
  beforehand, provided that row is still present afterward.
- **collapse-stops-watching-children**: Collapsing a directory row MUST remove
  its child-change subscription.
- **expand-persists-to-restoration**: A user-initiated expansion (one not
  performed while restoring state) MUST record that path as expanded in the
  restoration model.
- **collapse-persists-to-restoration**: A user-initiated collapse MUST record
  that path as not expanded in the restoration model.
- **programmatic-expand-collapse-not-persisted**: An expansion or collapse
  performed by the component itself — restoring saved disclosure, expanding
  a reveal's ancestors, or the test-only collapse-all operation — MUST NOT be
  written to the restoration model.
- **lone-root-auto-expands-once**: The first time the outline reloads while
  `restoration.expandedPaths` is empty and there is exactly one root manager,
  that root MUST be expanded automatically; this automatic expansion MUST
  happen at most once for the life of the component.
- **restore-expanded-paths-on-reload**: After any full reload, every currently
  drawn row whose path the restoration model reports as expanded, and which
  is not already expanded, MUST be expanded.
- **restore-descends-incrementally**: Restoring a selected path more than one
  unread level deep MUST proceed one additional level per reload triggered by
  that level's children arriving, rather than requiring the whole path to be
  drawn in a single pass.
- **missing-selection-abandonment**: If the directory that should contain
  a pending restored selection is drawn, expanded, and has finished reading
  its contents without that path appearing in them, the pending restoration
  MUST be dropped rather than left standing indefinitely.
- **select-root-sets-target-root**: Selecting a root's header row MUST set
  `selection.selectedRoot` to that root's URL.
- **select-node-sets-node-and-target-root**: Selecting a file or directory row
  MUST set `selection.selectedNode` to that row's node, and, if the node's URL
  falls under one of `directories`' roots, MUST also set
  `selection.selectedRoot` to that root.
- **select-persists-path-unless-restore-pending**: A selection change MUST be
  recorded as the selected path in the restoration model, except while a
  selection restore from a previous launch is still pending.
- **select-opens-file**: Selecting a row MUST run the open-if-file operation
  on the newly selected node.
- **open-skips-plain-directories**: The open-if-file operation MUST NOT
  invoke `onOpenRequest` for a node that is a directory and not a package.
- **open-opens-files-and-packages**: The open-if-file operation MUST invoke
  `onOpenRequest` with the node's URL and `.current` for a file or a package.
- **external-selection-highlights-and-scrolls**: When `selection.selectedNode`
  changes to a value different from what the outline currently has selected,
  and the corresponding row is drawn, that row MUST become the outline's
  selection and MUST be scrolled into view.
- **external-selection-suppresses-writeback**: Applying an externally-driven
  selection change (the previous requirement) MUST NOT cause that same value
  to be written back into `selection` through the outline's own
  selection-change notification.
- **external-deselect-clears-highlight**: When `selection.selectedNode`
  becomes `nil` while a node's row is the outline's selection, the outline
  MUST deselect all rows.
- **target-root-header-emphasis**: The root header row whose URL equals
  `selection.selectedRoot` MUST render its label with the `.primaryText` role;
  every other root header row MUST render with `.secondaryText`.
- **target-root-change-redraws-headers**: A change to `selection.selectedRoot`
  MUST reload the outline so header emphasis is redrawn; a republish of the
  same value MUST NOT trigger a reload.
- **managers-list-change-reloads**: A change to `roots.managers` MUST rebuild
  the per-manager subscriptions and reload the outline.
- **root-node-change-reloads**: A change to any manager's `rootNode` MUST
  reload the outline.
- **syncing-change-reloads**: A change to any manager's `isSyncing` MUST
  reload the outline.
- **reload-preserves-selection**: A full reload MUST re-select whatever row
  was selected immediately beforehand, if that row (by identity, or by path
  when identity changed) is still present afterward.
- **reload-clears-selection-when-row-gone**: If the row selected before a full
  reload is a node and is no longer present afterward (by identity or by
  path), `selection.selectedNode` MUST be set to `nil`.
- **path-lookup-correct-after-structural-change**: A lookup for the row
  currently displaying a given path MUST return the row that is actually
  showing that path (or report "not drawn") immediately after any reload,
  expansion, or collapse — never a stale answer left over from before that
  change.
- **row-lookup-avoids-full-scan**: A path lookup SHOULD be answered from a
  cached path-to-row index rather than scanning every drawn row on each call,
  rebuilding that index only when a structural change may have invalidated it.
- **dirty-updates-row-in-place**: A document open, change, dirty-state-change,
  or close event for a URI whose row is drawn and whose row view is currently
  instantiated MUST update only that row view's unsaved-changes marker,
  without reloading or reselecting anything.
- **dirty-falls-back-to-item-reload**: If the drawn row's view has been
  recycled away, the same event MUST instead reload that one item, in a way
  that does not clear the outline's current selection.
- **dirty-ignored-when-row-not-drawn**: A document event for a URI with no
  currently drawn row MUST be ignored.
- **dirty-marker-always-built**: A file row's unsaved-changes marker view MUST
  always be constructed as part of the row, and MUST be shown or hidden rather
  than added or removed after construction.
- **reveal-noop-if-already-shown**: Calling the reveal operation with the
  URL already selected MUST do nothing.
- **reveal-expands-drawn-ancestors**: The reveal operation MUST expand every
  ancestor directory of the target URL that is currently drawn and not
  already expanded.
- **reveal-selects-and-scrolls-when-drawn**: If the target row is drawn once
  its ancestors are expanded, the reveal operation MUST select it and scroll
  it into view.
- **reveal-writes-model-directly**: The reveal operation and the clear-reveal
  operation MUST write the resulting selection into `selection.selectedNode`
  (and `selection.selectedRoot`, when the URL falls under a known root)
  directly, rather than relying on the outline's own selection-change
  notification to do it.
- **reveal-defers-when-not-drawn**: If the target row is not yet drawn, the
  reveal operation MUST record it as a pending selection that later reloads
  complete once the relevant directory's contents arrive.
- **reveal-nothing-clears-selection**: Calling the clear-reveal operation MUST
  deselect all rows and MUST set `selection.selectedNode` to `nil`.
- **context-menu-uses-clicked-row**: The context menu MUST be built for the
  row under the cursor, not for the currently selected row.
- **context-menu-omitted-for-missing-path**: Context menu items MUST NOT be added for a row whose path no longer exists on disk.
- **context-menu-hides-open-items-for-directories**: The "Open", "Open in a
  New Tab", and "Open to the Side" items MUST be omitted for a path that is a
  directory.
- **context-menu-item-order**: When both groups of items apply, the menu MUST
  list the open items first, then a separator, then "Reveal in Finder" and
  "Copy Path".
- **context-menu-open-forwards-destination**: Choosing "Open", "Open in a New
  Tab", or "Open to the Side" MUST call `onOpenRequest` with the row's URL and
  `.current`, `.newTab`, or `.toTheSide` respectively.
- **context-menu-reveal-in-finder**: Choosing "Reveal in Finder" MUST invoke
  the platform's reveal-in-file-manager action with the row's URL (see
  Platform Notes for the exact API used on Apple platforms).
- **copy-path-format**: Choosing "Copy Path" MUST place the
  URL's POSIX path (not a `file://` URL string) on the general pasteboard.
- **double-click-toggles-root**: Double-clicking a root header row MUST expand
  it if collapsed, or collapse it if expanded.
- **double-click-toggles-loaded-node**: Double-clicking a node whose
  `children` is non-`nil` MUST toggle its expansion.
- **double-click-opens-otherwise**: Double-clicking a node whose `children` is
  `nil` MUST run the open-if-file operation instead of toggling expansion.
- **icon-chosen-by-node-type**: A row's icon MUST resolve to the package icon
  for a package; for a directory, a name-specific icon (`.claude` gets the
  AI-assistant-directory icon, `.git` gets the version-control-directory
  icon, `Sources`/`Source`/`src` get the source-directory icon,
  `Tests`/`test`/`tests` get the test-directory icon, any other dot-prefixed
  name gets the hidden-configuration-directory icon, everything else gets
  the generic directory icon); for a file, an icon resolved by extension — a
  user-configured custom mapping first, then a shared built-in extension
  table, falling back to the generic document icon when neither matches (see
  Platform Notes for the exact icon identifiers used on Apple platforms).
- **icon-tint-by-role**: The icon's tint MUST come from the palette:
  `.warning` for a package, `.info` for a directory literally named
  `.claude`, `.accent` for every other directory, `.warning` for `.swift` and
  `.json` files, `.accent` for `.md` and `.markdown` files, and
  `.secondaryText` for any other file extension.
- **name-truncation**: A file or directory's name label MUST
  truncate in the middle when it does not fit, and MUST render on a single
  line.
- **name-tooltip-is-full-path**: A file or directory row's name label MUST
  carry the node's full filesystem path as its tooltip.
- **git-status-recolors-name**: When a node has a non-`nil` `gitStatus`, its
  name label's text color MUST be overridden to that status's fixed color,
  not a theme role.
- **git-status-shows-badge**: When a node has a non-`nil` `gitStatus`, its row
  MUST show a trailing badge whose text is that status's single display
  character, colored with the same fixed status color.
- **tree-carries-accessibility-id**: The outline view MUST carry the
  accessibility identifier `file-browser.tree`.
- **keyboard-and-typeahead-inherited**: The outline MUST support standard
  tree-outline keyboard navigation — arrow-key row movement and
  expand/collapse, and type-ahead row selection — since this component
  overrides none of that behavior (see Platform Notes for the mechanism
  used on Apple platforms).
- **restore-disclosure-noop-without-pending**: The disclosure-restore
  operation MUST do nothing further once the ancestor-expansion pass
  completes when there is no pending restored selection
  (`pendingSelectionPath == nil`).
- **document-event-ignores-unparseable-uri**: A document event whose URI does
  not parse into a valid file location MUST be silently ignored.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

