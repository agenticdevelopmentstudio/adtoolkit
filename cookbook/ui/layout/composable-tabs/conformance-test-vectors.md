
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| composable-tabs-001 | binary-or-solo-children | The multi-child constructor is given 3 children | Construction traps (an assertion failure) in a debug build |
| composable-tabs-003 | vertical-split-set-from-axis | Construct with a horizontal axis, then load | The divider is drawn vertically |
| composable-tabs-004 | thin-divider-style | Load the split | The divider style is thin |
| composable-tabs-005 | custom-split-view-type | Inspect the split view after it loads | The split view is the component's own themed implementation, not a stock one |
| composable-tabs-006 | gutter-spacing-observers | The view is loaded with a spy split view that records spacing-change notifications; the between-columns pane spacing setting is changed | The spy records exactly one spacing-change notification, and the split view is marked for redraw immediately afterward |
| composable-tabs-007 | add-split-item-per-child | Construct with 2 children, then load | There are exactly 2 split items, in the same order as the children |
| composable-tabs-008 | reassign-identifiers-on-root-load | Construct a root split with two panes of the same pane type, then load | Both panes receive non-none, sequential indices from reassigning pane identifiers |
| composable-tabs-009 | schedule-persist-on-resize | Preferred thicknesses already applied once; the split view reports a resize | A debounced persist is scheduled on the root; flushing the pending persist now performs a write |
| composable-tabs-010 | apply-preferred-thickness-on-layout | A layout pass runs with a real (non-placeholder) split-view width | Divider positions are set from each child's thickness fraction |
| composable-tabs-011 | preferred-thickness-one-shot | Thicknesses already applied for the current arrangement; a further layout pass runs | No divider position is changed by the second pass |
| composable-tabs-012 | skip-zero-thickness-pass | The split view's width is `0`; a layout pass runs | No divider position is set; when a layout pass later runs with a real width, thicknesses are still applied then (the skip did not consume the one-shot) |
| composable-tabs-013 | dragged-fraction-outranks-descriptor | Child's own thickness fraction is `0.7`; its split item's preferred thickness fraction is `0.3` | The divider is placed using `0.7`, not `0.3` |
| composable-tabs-014 | clamp-thickness-to-minimum | Fraction implies a thickness below the item's minimum thickness | The divider is placed at the minimum thickness, not the smaller fraction-derived value |
| composable-tabs-015 | widen-divider-grab-area | Gutter is set to `0`pt (vertical split); the platform asks for the divider's effective hit-test rectangle | The returned rectangle is inset to at least the minimum divider grab width (6pt) wide while the drawn rectangle stays at 0pt |
| composable-tabs-016 | stamp-ownership-on-children | Assign children = [pane, nestedSplit] | The pane's host is this component and the nested split's layout parent is this component |
| composable-tabs-017 | inherit-arranger-to-nested-splits | Set arranger to a proportional arranger with a nested split among the children | The nested split's arranger is the same proportional-arranger instance |
| composable-tabs-018 | inherit-layout-override | Set layout override to a non-none value | Every pane and nested split among the children reports the same layout override |
| composable-tabs-019 | inherit-state-owner-node-id | Set state-owner node identifier to a fresh identifier | Every pane and nested split among the children reports the same state-owner node identifier |
| composable-tabs-020 | inherit-clamps-to-container | Set clamps-to-container to `true` | Every pane and nested split among the children reports clamps-to-container `true` |
| composable-tabs-021 | default-arranger-is-inherited-slot | Read the arranger on a freshly constructed component | It is the inherited-slot arranger, and applying it returns the node unchanged |
| composable-tabs-022 | apply-arrangement-no-op-for-default-arranger | Arranger is the default; apply the arrangement | No thickness fraction on any child changes and no layout pass is forced |
| composable-tabs-023 | apply-arrangement-resolves-actual-axis | Root holds one child that is itself a vertical split; apply a non-default arranger | The arranger is invoked with the vertical axis, not the root's own axis |
| composable-tabs-024 | apply-arrangement-matches-by-id | Arranger's result omits one child's identifier | That child's existing thickness fraction is left unchanged after fractions are applied |
| composable-tabs-025 | capture-thicknesses-on-mutation | User has dragged a divider; a split is performed | The pre-split live thickness is captured into the affected child's thickness fraction before the tree changes |
| composable-tabs-026 | capture-skips-zoomed-tree | Root's zoomed leaf is set; thicknesses are captured | No child's thickness fraction anywhere in the tree is modified |
| composable-tabs-027 | capture-skips-rail-split | One split's visible item is pinned to a fixed rail thickness; thicknesses are captured on it | No item in that split has its thickness fraction written |
| composable-tabs-028 | capture-only-uncollapsed-items | One item in a split is collapsed; thicknesses are captured | The collapsed item's child does not have its thickness fraction overwritten |
| composable-tabs-029 | capture-recurses-into-children | A rail split contains a nested split with its own children | Capturing thicknesses still descends into and updates the nested split's own children |
| composable-tabs-030 | apply-sizes-matches-existing-shape | Live tree has 1 child; template layout node is a 2-child split | Applying sizes leaves the live tree's single child untouched |
| composable-tabs-031 | apply-sizes-forces-relayout | Sizes are applied from a template on a loaded view | The one-shot thickness guard is reset and dividers move to the new fractions before the next natural layout pass |
| composable-tabs-032 | debounce-thickness-persist | Two resize notifications arrive 100ms apart | Only one layout-change callback happens, timed 300ms after the second notification |
| composable-tabs-033 | dedupe-unchanged-persist | A pending persist's rounded thickness signature matches the signature already delivered to the layout-change callback | The layout-change callback is not invoked |
| composable-tabs-034 | flush-pending-persist-on-demand | No persist is currently pending; a flush is requested | The layout-change callback is not invoked and no error occurs |
| composable-tabs-035 | persist-only-from-root | A persist is scheduled on a non-root split | No persist is armed and no write ever occurs from that instance; a subsequent flush on it still does nothing |
| composable-tabs-036 | split-creates-sibling-pane | Split a pane, adding a new view to its right | A new pane showing that view is added as the second child of a new inner split, the original pane as the first |
| composable-tabs-037 | split-wraps-in-inner-split | Same split as above | The original slot is replaced by a new split node laid out horizontally (from the given direction's axis) |
| composable-tabs-038 | split-inherits-slot-size | Pane's thickness fraction is `0.4` before the split | The new inner split's thickness fraction is `0.4`; the pane's own fraction is none afterward |
| composable-tabs-039 | split-propagates-configuration | Enclosing split has a custom arranger, layout override, state-owner node identifier, clamps-to-container `true` | The new inner split reports all four of the same values |
| composable-tabs-040 | split-persists-and-rearranges | A split completes | The arrangement is applied and the layout-change callback fires from the root |
| composable-tabs-041 | remove-refuses-non-direct-child | Remove a pane not in this split | The children are unchanged and no split item is removed |
| composable-tabs-042 | remove-honors-spec-veto | Layout spec's remove-check returns `false` for the given leaf | Removal returns with the children unchanged |
| composable-tabs-043 | remove-tears-down-pane-content | Removal of a pane succeeds | The pane's host is none and it has been notified of its removal exactly once |
| composable-tabs-044 | remove-clears-sibling-fractions | Split has 2 children, each with a non-none fraction; one is removed | The remaining child's thickness fraction is none after removal |
| composable-tabs-045 | remove-collapses-degenerate-split | Non-root split with 2 children; one is removed | The split itself is replaced in its parent by the surviving child, at the collapsing split's former thickness fraction |
| composable-tabs-046 | remove-rehomes-focus | Removed pane's view held input focus | After removal, the root's first leaf (depth-first) receives input focus |
| composable-tabs-047 | remove-persists-and-rearranges | A removal completes | The arrangement is applied and the layout-change callback fires from the root |
| composable-tabs-048 | move-refused-by-spec | Spec disallows the moved tree | Moving the leaf left returns `false`; the children are unchanged |
| composable-tabs-049 | available-directions-filtered-by-spec | Available move directions report left and right; spec disallows left's resulting tree | Only right remains available for the leaf |
| composable-tabs-050 | rebuild-reuses-live-panes | New shape's leaf id matches a currently-live pane's node identifier | Rebuilding reuses the exact same pane instance for that id |
| composable-tabs-051 | rebuild-tears-down-dropped-panes | New shape omits a leaf id that was live before | That leaf is notified of its removal exactly once |
| composable-tabs-052 | rebuild-detaches-before-rehosting | Rebuild is called on a loaded view | Every prior split item is removed and every prior child's host/layout-parent is none before any new item is added |
| composable-tabs-053 | rebuild-single-leaf-becomes-root-child | New shape is a single leaf node | The root's children has exactly 1 entry: that leaf's pane, with no extra nested split |
| composable-tabs-054 | rebuild-carries-thickness-fractions | Template layout node for a child has thickness fraction `0.25` | The constructed/reused child's thickness fraction is `0.25` |
| composable-tabs-055 | rebuild-persists-from-root | Rebuild completes | The layout-change callback fires from the root with the new snapshot |
| composable-tabs-056 | allowed-insertions-delegates-to-spec | Split has a root; allowed insertions beside a leaf are requested | Returns exactly what the layout spec returns for the root's snapshot |
| composable-tabs-057 | can-remove-leaf-delegates-to-spec | Split has no root | Checking whether a leaf may be removed returns `false` |
| composable-tabs-058 | root-split-walk-uses-is-root | A non-root split's view has never loaded (no parent in the view hierarchy) but its layout-parent chain reaches a node marked as root | Finding the root split returns that root, not none |
| composable-tabs-059 | tear-down-panes-notifies-every-leaf | Subtree has 3 leaves; panes are torn down | All 3 leaves are notified of removal exactly once each |
| composable-tabs-060 | reassign-ambiguous-pane-numbers | Tab has 2 terminals and 1 file browser | Both terminals get non-none, sequential indices; the file browser's index is none |
| composable-tabs-061 | persist-tree-only-from-root | Persisting the tree is requested on a non-root split | No pane identifiers are reassigned and the layout-change callback is not invoked |
| composable-tabs-062 | persist-tree-sequence | Root's tree persist is requested | Pane identifiers are reassigned, pane state is reapplied, pane controls are refreshed, the layout-change callback fires, then the notification is posted, all in that order |
| composable-tabs-063 | snapshot-unwraps-single-child | Split has exactly 1 child | The snapshot returns that child's own snapshot, not a wrapping split node |
| composable-tabs-064 | snapshot-empty-tree-is-placeholder | Split has 0 children | The snapshot returns a placeholder leaf |
| composable-tabs-065 | make-item-sizing | Pane's descriptor has minimum thickness `200`, is collapsible, preferred thickness fraction `0.3` | The built item has minimum thickness `200`, can collapse, preferred thickness fraction `0.3` |
| composable-tabs-066 | make-item-holding-priority | Clamps-to-container is `true` | The built item's holding priority is the fixed minimal value regardless of the descriptor |
| composable-tabs-067 | clamped-tree-has-no-minimum | Clamps-to-container is `true`; descriptor declares minimum thickness `300` | The built item's minimum thickness is left unspecified |
| composable-tabs-068 | restore-sizing-order | Item is currently pinned (rail); its sizing is restored | Its maximum thickness is cleared before minimum thickness/holding priority are reset (no transient invalid constraint pair is ever observed) |
| composable-tabs-069 | build-from-persisted-leaf-wraps-in-root-split | Construct from a persisted leaf node as root | The returned split's children has exactly 1 entry; its own axis is horizontal and its node identifier is freshly minted, not the leaf's id |
| composable-tabs-070 | build-carries-fraction-to-child | Persisted leaf node has thickness fraction `0.6` | The constructed pane's thickness fraction is `0.6` |
| composable-tabs-071 | close-checks-membership | Pane is not among the children of the split receiving the request | A refusal is announced; removal is never attempted |
| composable-tabs-072 | close-honors-spec-veto-with-fallback | Spec vetoes removal; no last-pane-close handler is set | A refusal is announced; the pane is not removed |
| composable-tabs-073 | close-honors-spec-veto-with-fallback | Spec vetoes removal; a last-pane-close handler is set; tab holds exactly 1 pane | The handler is invoked with the pane; removal is not attempted |
| composable-tabs-074 | close-clears-zoom-before-removal | Pane is the root's zoomed leaf; close is requested and permitted | The zoomed leaf is cleared by the time removal runs |
| composable-tabs-075 | can-close-mirrors-close-refusal | Spec allows removing the pane | Checking whether it can close returns `true` |
| composable-tabs-076 | minimize-refuses-unresolvable-edge | The requested edge cannot be resolved against the axis of the tree at the pane's position (for example, a leading/trailing edge requested where the enclosing split's axis is vertical) | No item is pinned and the pane's minimized state is not set |
| composable-tabs-077 | minimize-clears-zoom-first | Root is zoomed; a pane is minimized | The zoomed leaf becomes none; thicknesses are not re-captured for this minimize |
| composable-tabs-078 | minimize-pins-split-item | Minimize succeeds and an item exists | The item's minimum and maximum thickness both equal the pane's minimized thickness for the resolved edge; holding priority is high; preferred thickness fraction is unchanged |
| composable-tabs-079 | minimize-is-unconditional-on-model | Tab has never been displayed (no split item exists) | The pane's minimized state is still recorded |
| composable-tabs-080 | restore-unpins-and-clears | An item exists for a minimized pane; restore is requested | The item's sizing is restored and the pane's minimized state is cleared |
| composable-tabs-081 | zoom-toggles-and-excludes-minimize | A minimized pane is zoomed | The pane is restored first, then the zoomed leaf is set to that pane |
| composable-tabs-082 | zoom-collapses-off-path-items | Deep tree; a leaf 3 levels down is zoomed | Every split item not on the root-to-leaf path is collapsed; items on the path are not |
| composable-tabs-083 | zoom-preserves-tree-shape | A pane is zoomed then unzoomed | The snapshot before and after report identical structure and thickness fractions |
| composable-tabs-084 | persisted-state-applies-once | Applying persisted pane state is called twice on the same root instance | The second call has no additional effect: no leaf's minimize or zoom state changes as a result of it |
| composable-tabs-085 | persisted-minimize-restores-if-edge-invalid | A leaf's persisted edge no longer resolves against the current tree | The leaf is restored instead of minimized |
| composable-tabs-086 | reapply-pane-state-is-idempotent | Pane state is reapplied twice in a row with no tree change between calls | No additional resize notification or persist is triggered by the second call |
| composable-tabs-087 | reapply-drops-stale-zoom | Zoomed leaf points to a pane no longer among the tab's leaves | The zoomed leaf becomes none and every item is un-collapsed |
| composable-tabs-088 | reapply-reresolves-minimize-edge | A rebuild changed the axis under a minimized pane so its stored edge no longer applies, but a different edge does | The pane is minimized with the re-resolved edge, not the stale one |
| composable-tabs-089 | refresh-pane-controls-notifies-every-leaf | Tab has 3 leaves; pane controls are refreshed | Each of the 3 leaves' control-availability refresh is called exactly once |
| composable-tabs-090 | split-no-ops-without-project | The project has already gone away; a split adding a new view to the right is requested | The children are unchanged and no split item is added |
| composable-tabs-091 | move-permitted-without-spec | Resolved project has no layout spec configured at all | Moving the leaf left returns `true` and rebuilds the root from the moved tree |
| composable-tabs-092 | move-rebuilds-root | Spec permits the moved tree | Moving returns `true` and the root's children match the moved tree's shape |
| composable-tabs-093 | can-close-mirrors-close-refusal | Spec disallows removing the pane and no last-pane-close handler is installed | Checking whether it can close returns `false` |
| composable-tabs-094 | flush-pending-persist-on-demand | A resize notification has armed a pending debounced persist; a flush is requested before the debounce timer fires | The write happens immediately and no later timer-driven write follows |
| composable-tabs-095 | vertical-split-set-from-axis | Construct with a vertical axis, then load | The divider is drawn horizontally |
| composable-tabs-096 | reassign-identifiers-on-root-load | Construct a non-root split with two panes of the same pane type, then load | Neither pane's index is assigned by loading (reassignment does not run on a non-root instance) |
| composable-tabs-097 | persisted-state-applies-once | Leaf X has a persisted minimize edge and lies off the path to leaf Y, the persisted zoomed leaf; persisted pane state is applied | X's split item ends up both pinned (minimum thickness equal to maximum thickness) and collapsed — minimize pinned it before zoom collapsed it, so neither effect is lost |
| composable-tabs-098 | non-pointer-resize | Attempt to change a divider's thickness fraction with the keyboard alone | No thickness change occurs; only a pointer drag changes a divider's thickness. |
| composable-tabs-099 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

