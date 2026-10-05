
- **binary-or-solo-children**: Component's multi-child constructor MUST trap
  (in a debug build) when given more than two children; a split MUST be
  nested rather than given a third child directly.
- **vertical-split-set-from-axis**: Component MUST orient its divider from
  its axis — vertical when the axis is horizontal, horizontal when the axis
  is vertical — both at initial load and after every rebuild.
- **thin-divider-style**: Component MUST use a thin divider style, set at
  initial load.
- **custom-split-view-type**: Component MUST use its own themed split view
  implementation, rather than a generic one, as its split view.
- **gutter-spacing-observers**: Component MUST observe both gutter settings
  (the between-columns and between-rows spacing) from initial load onward,
  and MUST notify the split view whenever either one changes.
- **add-split-item-per-child**: Component MUST add exactly one split item for
  each of its children, in order, at initial load.
- **reassign-identifiers-on-root-load**: Component MUST reassign pane
  identifiers at initial load only when it is the tab's root.
- **schedule-persist-on-resize**: Component MUST schedule a debounced
  thickness persist, from the root, whenever the split view reports that its
  layout was resized, but only once preferred thicknesses have already been
  applied at least once for the current arrangement.
- **apply-preferred-thickness-on-layout**: Component MUST attempt to apply
  preferred/persisted thickness fractions to the split's dividers on every
  layout pass, until that application succeeds once for the current
  arrangement.
- **preferred-thickness-one-shot**: Component MUST NOT reapply preferred
  thickness fractions on a later layout pass once they have been applied for
  the current arrangement, and MUST reset that one-shot guard whenever the
  arrangement changes (a split, a removal, a rebuild, or applying sizes from
  a template).
- **skip-zero-thickness-pass**: Component MUST NOT apply preferred
  thicknesses when the split view's total extent along its axis is `1` or
  less, or when the number of installed split items does not yet equal the
  number of children.
- **dragged-fraction-outranks-descriptor**: When applying preferred
  thicknesses, Component MUST prefer a child's own thickness fraction (what
  the user dragged, or what was restored from storage) over the split item's
  preferred thickness fraction, and MUST fall back to the item's preferred
  thickness fraction only when the child has no stored fraction.
- **clamp-thickness-to-minimum**: When a fraction is being applied for a
  divider, Component MUST clamp the resulting thickness to at least that
  item's minimum thickness.
- **widen-divider-grab-area**: Component MUST widen a divider's effective
  (draggable) hit-test area, on the axis it is drawn thinner than the minimum
  divider grab width (6pt), to at least that width, without changing the area
  actually drawn.
- **stamp-ownership-on-children**: Component MUST set itself as host on every
  pane among its children and as layout parent on every nested split node
  among its children, both at initialization and whenever its children are
  reassigned.
- **inherit-arranger-to-nested-splits**: When stamping ownership, Component
  MUST propagate its own arranger to every nested split child.
- **inherit-layout-override**: When stamping ownership, Component MUST
  propagate its own layout override to every pane and nested split child.
- **inherit-state-owner-node-id**: When stamping ownership, Component MUST
  propagate its own state-owner node identifier to every pane and nested
  split child.
- **inherit-clamps-to-container**: When stamping ownership, Component MUST
  propagate its own clamps-to-container setting to every pane and nested
  split child.
- **default-arranger-is-inherited-slot**: Component MUST default its arranger
  to the inherited-slot arranger, which returns its input tree with thickness
  fractions unchanged.
- **apply-arrangement-no-op-for-default-arranger**: Applying the arrangement
  MUST have no observable effect when the installed arranger is the
  inherited-slot arranger (see **default-arranger-is-inherited-slot** for
  why: that arranger returns its input unchanged).
- **apply-arrangement-resolves-actual-axis**: When applying a non-default
  arranger, Component MUST hand the arranger the axis of its own snapshot's
  split orientation when that snapshot is itself a split node, rather than
  always using its own axis.
- **apply-arrangement-matches-by-id**: Component MUST match the fractions an
  arranger returns back onto the live children by comparing node identifier,
  and MUST leave any live child the arranger's result did not describe with
  its existing fraction unchanged.
- **capture-thicknesses-on-mutation**: Component MUST capture the live
  divider thicknesses of the whole tab into each child's thickness fraction,
  from the root, immediately before a split or remove mutation changes the
  tree.
- **capture-skips-zoomed-tree**: Component MUST NOT capture thickness
  fractions anywhere in the tab's tree while the root's zoomed leaf is set.
- **capture-skips-rail-split**: Component MUST NOT capture thickness
  fractions for a split any of whose visible items is pinned to a fixed rail
  thickness (a maximum thickness that is no longer unspecified).
- **capture-only-uncollapsed-items**: When capturing thicknesses, Component
  MUST record a fraction only for items that are not currently collapsed.
- **capture-recurses-into-children**: Capturing thickness fractions MUST
  recurse into every nested split child regardless of whether the split
  itself just captured a fraction.
- **apply-sizes-matches-existing-shape**: Applying sizes from a template MUST
  copy thickness fractions from the template layout node onto the live tree
  only at levels where the live child count (`1` or `2`) matches the
  template's shape, and MUST leave a mismatched subtree untouched rather than
  partially applying sizes to it.
- **apply-sizes-forces-relayout**: After adopting new sizes, applying sizes
  from a template MUST reset the one-shot thickness-application guard and
  MUST immediately reapply thicknesses for any subtree whose view is already
  loaded.
- **debounce-thickness-persist**: Component MUST debounce a divider-driven
  persist by 300ms after each reported resize, canceling any still-pending
  write each time a new resize notification arrives.
- **dedupe-unchanged-persist**: Component MUST NOT invoke its layout-change
  callback when the rounded thickness signature of the current snapshot is
  unchanged from the last one persisted.
- **flush-pending-persist-on-demand**: Component MUST provide a way to flush
  a pending thickness persist immediately, which MUST write a still-pending
  debounced persist immediately and MUST do nothing when no persist is
  currently pending.
- **persist-only-from-root**: Component MUST schedule, flush, and perform a
  thickness persist only when it is the root; a non-root split MUST NOT
  independently start or flush a persist timer.
- **split-creates-sibling-pane**: Splitting a pane MUST create a new pane
  showing the given view identifier as a sibling of the pane being split, and
  MUST place the new sibling first or second in the resulting inner split
  according to whether the given direction places the new pane first.
- **split-wraps-in-inner-split**: Splitting a pane MUST replace the split
  pane's slot with a new nested split node holding exactly the original pane
  and the new sibling, laid out along the given direction's own axis.
- **split-inherits-slot-size**: The new inner split created by a split MUST
  inherit the thickness fraction the original pane held in its slot, and the
  original pane's own fraction MUST be cleared, so the two panes start out
  sharing the inner split evenly.
- **split-propagates-configuration**: The inner split created by a split MUST
  end up with the enclosing split's arranger, layout override, state-owner
  node identifier, and clamps-to-container setting, per
  **inherit-arranger-to-nested-splits**, **inherit-layout-override**,
  **inherit-state-owner-node-id**, and **inherit-clamps-to-container**.
- **split-persists-and-rearranges**: After a split completes, Component MUST
  apply the arrangement and persist the tree, both from the root.
- **split-no-ops-without-project**: A split MUST return immediately,
  performing no mutation, when its project has already gone away.
- **remove-refuses-non-direct-child**: Removing a pane MUST have no effect
  when the given pane is not a direct child of the split it is called on.
- **remove-honors-spec-veto**: Removing a pane MUST have no effect when the
  root's layout spec refuses to remove the given leaf.
- **remove-tears-down-pane-content**: Removing a pane MUST clear the removed
  pane's host and MUST notify it that it is being removed, after detaching it
  from the split view.
- **remove-clears-sibling-fractions**: After a removal, Component MUST clear
  the thickness fraction of every remaining child in that split, since those
  fractions described a split that no longer exists.
- **remove-collapses-degenerate-split**: When a non-root split is left with
  exactly one child after a removal, Component MUST collapse that split out
  of the tree, promoting the surviving child into the collapsing split's own
  slot (inheriting its thickness fraction) in the parent split.
- **remove-rehomes-focus**: If the removed pane held input focus, removing it
  MUST move input focus to the root's first leaf (depth-first order) once
  removal completes.
- **remove-persists-and-rearranges**: After a removal completes, Component
  MUST apply the arrangement and persist the tree, both from the root.
- **move-refused-by-spec**: Moving a pane MUST compute the candidate new tree
  via the move-resolution logic against the root's current snapshot, and MUST
  return `false` without mutating the tree when the project's layout spec
  disallows the resulting tree.
- **move-permitted-without-spec**: Moving a pane MUST treat a resolved
  project that has no layout spec configured at all as permitting the move,
  rather than refusing it.
- **move-rebuilds-root**: When the candidate tree is permitted (by
  **move-refused-by-spec** or **move-permitted-without-spec**), moving a pane
  MUST rebuild the root from that tree and return `true`.
- **available-directions-filtered-by-spec**: Computing the available move
  directions for a pane MUST return only the directions, among those the
  move-resolution logic reports as available, for which the resulting moved
  tree is allowed by the project's layout spec.
- **rebuild-reuses-live-panes**: Rebuilding from a template MUST reuse an
  existing live pane for any leaf id that survives into the new shape, rather
  than constructing a new pane for that id.
- **rebuild-tears-down-dropped-panes**: Rebuilding MUST notify every
  previously-live leaf whose id does not appear among the new shape's leaf
  ids that it is being removed.
- **rebuild-detaches-before-rehosting**: Rebuilding MUST detach every current
  child (clearing its host/layout-parent, and removing its split item when
  the view is loaded) before constructing the new tree.
- **rebuild-single-leaf-becomes-root-child**: When the rebuilt shape is a
  single leaf, rebuilding MUST host it as the split's sole child rather than
  wrapping it in a further nested split.
- **rebuild-carries-thickness-fractions**: Every child constructed or reused
  during a rebuild MUST receive the thickness fraction recorded on its
  corresponding layout node.
- **rebuild-persists-from-root**: Rebuilding MUST persist the tree from the
  root after rebuilding.
- **allowed-insertions-delegates-to-spec**: Computing the allowed insertions
  beside a leaf MUST return the result of asking the layout spec, given the
  root's current snapshot and view registry, and MUST return an empty list
  when the split has no root.
- **can-remove-leaf-delegates-to-spec**: Checking whether a leaf may be
  removed MUST return the result of asking the layout spec whether the given
  leaf may be removed from the root's current snapshot, and MUST return
  `false` when the split has no root.
- **root-split-walk-uses-is-root**: Finding the root split MUST walk up
  through each split's layout parent until it reaches the node marked as
  root, and MUST NOT stop merely because a node currently has no visible
  parent in the view hierarchy.
- **tear-down-panes-notifies-every-leaf**: Tearing down panes MUST notify
  every leaf in the subtree that it is being removed.
- **reassign-ambiguous-pane-numbers**: Reassigning pane identifiers MUST
  assign a 1-based index only to leaves whose pane type occurs more than once
  among the tab's leaves (in depth-first order), and MUST clear the index
  (assign none) on every leaf whose type is unique in the tab.
- **persist-tree-only-from-root**: Persisting the tree MUST have no effect
  when Component is not the root.
- **persist-tree-sequence**: When Component is the root, persisting the tree
  MUST, in this order: reassign pane identifiers, reapply pane state, refresh
  pane controls, invoke the layout-change callback with the current snapshot,
  and post a layout-changed notification with itself as the notification's
  subject.
- **snapshot-unwraps-single-child**: Taking a snapshot MUST return the
  snapshot of its sole child directly, without an enclosing split node, when
  the split holds exactly one child.
- **snapshot-empty-tree-is-placeholder**: Taking a snapshot MUST return a
  placeholder leaf node when the split holds zero children.
- **make-item-sizing**: Building a split item for a child MUST set the
  resulting item's minimum thickness from the recursive minimum-thickness
  computation over the registered view descriptor(s) beneath that child, MUST
  set whether it can collapse from the pane's descriptor (`false` for a
  non-pane child), and MUST set its preferred thickness fraction from the
  descriptor when the descriptor declares one.
- **make-item-holding-priority**: Building a split item MUST set the item's
  holding priority to the descriptor's resolved holding priority unless the
  split's clamps-to-container setting is `true`, in which case it MUST use
  the fixed, minimal priority.
- **clamped-tree-has-no-minimum**: When clamps-to-container is `true`, an
  item's minimum thickness MUST be left unspecified regardless of the
  descriptor's declared minimum.
- **restore-sizing-order**: Restoring an item's sizing MUST clear the item's
  maximum thickness before it lowers its minimum thickness and resets its
  holding priority back to their registered values.
- **build-from-persisted-leaf-wraps-in-root-split**: Constructing from a
  persisted layout node MUST host a top-level leaf node inside a newly
  created, non-persisted wrapper split (a fresh node identifier, horizontal
  axis) when building the root, so a tab always has a split at its root.
- **build-carries-fraction-to-child**: Constructing a child from a persisted
  layout node MUST transfer that node's thickness fraction onto the
  constructed or reused child.
- **close-checks-membership**: Requesting a pane's close MUST decline the
  request, announcing a refusal, when the pane is not currently a direct
  child of the split that receives the request.
- **close-honors-spec-veto-with-fallback**: Requesting a pane's close MUST
  refuse (announcing a refusal) when the root's layout spec disallows
  removing the pane and either no last-pane-close handler is installed on the
  root or the tab holds more than that one pane; when a handler is installed
  and the pane is the tab's only pane, it MUST invoke that handler instead of
  removing the pane.
- **close-clears-zoom-before-removal**: Requesting a pane's close MUST clear
  the root's zoomed leaf before removing a pane that is currently the zoomed
  leaf.
- **can-close-mirrors-close-refusal**: Checking whether a pane can close MUST
  return `true` exactly when requesting its close would actually remove the
  pane or hand it to a last-pane-close handler (the spec allows removing it,
  or a handler exists and the tab holds exactly one pane).
- **minimize-refuses-unresolvable-edge**: Requesting a pane's minimize MUST
  have no effect when the requested edge cannot be resolved against the axis
  of the tree at that pane's position.
- **minimize-clears-zoom-first**: Requesting a pane's minimize MUST clear any
  existing zoom before minimizing a pane, and in that case MUST NOT
  re-capture thickness fractions (the fractions captured on the way into the
  zoom are preserved instead).
- **minimize-pins-split-item**: Requesting a pane's minimize MUST pin the
  owning split item to the pane's minimized thickness for the resolved edge
  by setting its minimum thickness equal to its maximum thickness and raising
  its holding priority to a high priority, without altering its preferred
  thickness fraction.
- **minimize-is-unconditional-on-model**: Requesting a pane's minimize MUST
  record the pane's minimized state even when the tab has never been
  displayed and no split item yet exists to pin.
- **restore-unpins-and-clears**: Requesting a pane's restore MUST restore the
  owning split item's sizing when an item exists, and MUST clear the pane's
  minimized state regardless of whether an item exists.
- **zoom-toggles-and-excludes-minimize**: Requesting a pane's zoom MUST
  restore a minimized pane before zooming it, and MUST toggle the root's
  zoomed leaf between the given pane and none.
- **zoom-collapses-off-path-items**: Setting the zoomed leaf MUST collapse
  every split item that does not lie on the path from the root down to the
  zoomed leaf, and MUST un-collapse every item when the target is cleared.
- **zoom-preserves-tree-shape**: Zooming MUST NOT reparent, remove, or resize
  (in thickness-fraction terms) any node in the tree; only each split item's
  collapsed flag changes.
- **persisted-state-applies-once**: Applying persisted pane state MUST run at
  most once per root instance, MUST apply minimize state before zoom state,
  and MUST have no effect when Component is not the root.
- **persisted-minimize-restores-if-edge-invalid**: When a leaf's persisted
  minimize edge cannot be resolved against the current tree, applying
  persisted pane state MUST restore that pane instead of leaving it minimized
  with no way for the user to undo it.
- **reapply-pane-state-is-idempotent**: Reapplying pane state MUST run on
  every rebuild (it holds no one-shot latch), and re-applying a collapsed or
  pinned state that is already correct MUST NOT trigger an additional resize
  notification.
- **reapply-drops-stale-zoom**: Reapplying pane state MUST clear the root's
  zoomed leaf and un-collapse the tree when the zoomed leaf is no longer
  present among the tab's leaves.
- **reapply-reresolves-minimize-edge**: Reapplying pane state MUST
  re-resolve each minimized leaf's edge against the current tree rather than
  trust the edge it was last minimized to, and MUST restore the pane instead
  when no edge remains valid.
- **refresh-pane-controls-notifies-every-leaf**: Refreshing pane controls
  MUST re-ask every leaf in the tab to refresh its own control availability.
- **custom-arranger**: Component MAY be configured with a custom arranger
  (for example, a proportional arranger) in place of the default
  inherited-slot arranger, to redistribute thickness fractions along the
  arrangement axis differently than "leave what a split/remove already
  assigned."
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

