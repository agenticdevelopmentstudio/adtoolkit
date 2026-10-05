
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tab-bar-view-001 | thickness-floor-by-edge | Query the bar's preferred thickness for the top edge, then for the left edge | Returns `28`; the left edge returns `140` |
| tab-bar-view-002 | orientation-follows-edge | A bar is built for the right edge | Its arranged content lays out vertically (top-to-bottom) |
| tab-bar-view-003 | alignment-favors-workspace-side | A bar is built for the top edge | Items align to the bar's bottom edge |
| tab-bar-view-004 | item-spacing-by-orientation | A bar is built for the left edge | The gap between adjacent items is `-16pt` (items overlap) |
| tab-bar-view-005 | start-inset-defaults-to-end-padding | A new bar is built | The start inset is `8`; the first item begins `8pt` from the bar's start |
| tab-bar-view-006 | host-may-override-start-inset | The start inset is set to `20` | The first item now begins `20pt` from the bar's start |
| tab-bar-view-007 | outer-padding-on-window-side-only | A bar is built for the bottom edge | Items sit `6pt` from the bar's outer (window) edge, flush (`0pt`) against the workspace edge, and `8pt` from each end along the bar's length |
| tab-bar-view-008 | bar-fills-perpendicular-and-pins-length | A bar is built for the top edge and laid out in a 300pt-wide container | The bar's arranged content spans the bar's own leading/trailing edges; the bar's height is `28` at rest |
| tab-bar-view-009 | vertical-bar-packs-from-top | A bar is built for the left edge with 2 short items in a tall container | The bar's arranged content is shorter than the bar's own height; the gap below is empty, not stretched |
| tab-bar-view-010 | bar-fills-window-background | The active theme changes from theme A to theme B | The bar's background updates to theme B's `windowBackground` color |
| tab-bar-view-011 | set-items-triggers-rebuild | Set the bar's items to a single item, selected | The bar renders exactly one item, matching the new item |
| tab-bar-view-012 | set-selected-restyles-and-reorders | Two title items; select the second one | The tab for the second item is highlighted; the tab for the first is not |
| tab-bar-view-013 | stack-depth-by-distance-from-selection | 3 content-hosting items at indices 0,1,2; select index 0 | Depths reported to the hosted items are `0, 1, 2` |
| tab-bar-view-014 | stack-depth-by-distance-from-selection | Same 3 items; nothing selected | Every item's reported depth is `1` |
| tab-bar-view-015 | vertical-edge-cards-overlap-and-order-by-distance | A left-edge bar, 3 hosted items, the middle one selected | The middle item's wrapper view is above both neighbors (frontmost, topmost hit-tested) |
| tab-bar-view-016 | rename-title-item | Rename an existing title tab to "New" | The item's payload is a title item reading "New"; the tab button's displayed title reads "New" |
| tab-bar-view-017 | rename-title-item | Rename a tab using an id with no matching item | No crash; the items and rendered buttons are unchanged |
| tab-bar-view-018 | rebuild-clears-and-repopulates | Set items to [a, b], then set items to [c] | The bar renders exactly one item, c's; no rendered element for a or b remains |
| tab-bar-view-019 | cross-edge-move-preserves-foreign-content | A hosted item's view is reparented onto a different bar's wrapper, then this bar is given new items | The item's parent and view are unaffected by this bar's reconciliation |
| tab-bar-view-020 | rebuild-drops-stale-hosted-content | A content-hosting item is removed from the items and the bar re-renders | The removed item's content no longer receives highlight or stack-depth updates from the bar |
| tab-bar-view-021 | title-item-becomes-button | A title item on a left-edge bar | The created tab button has active constraints pinning its leading/trailing edges to the bar's interior |
| tab-bar-view-022 | title-item-becomes-button | A title item on a top-edge bar | The created tab button has no cross-axis pin installed by the bar (relies on the bar's own alignment) |
| tab-bar-view-023 | content-item-becomes-hosted-view | A content-hosting item on a top-edge bar | The wrapping hosted-item view has active top/bottom constraints pinning it to the bar's interior |
| tab-bar-view-024 | thickness-grows-with-hosted-content | A left-edge bar hosts an item with a preferred width of `200` | The bar's thickness (width) is `206` (`200 + 6`, above the `140` floor) |
| tab-bar-view-025 | thickness-grows-with-hosted-content | A left-edge bar with no hosted items | The bar's thickness (width) is `140` (the floor) |
| tab-bar-view-026 | host-view-fills-hosted-content | A hosted-item wrapper is constructed around a content view | The content view's top/leading/trailing/bottom equal the wrapper's own edges |
| tab-bar-view-027 | host-view-click-selects | A pointer-down lands inside the wrapper but outside any interior control | The tab is selected |
| tab-bar-view-028 | close-icon-hit-routes-to-close | A pointer-down lands inside the close button's frame | The close action fires; the tab is not also selected by this pointer-down |
| tab-bar-view-029 | close-icon-hit-routes-to-close | A pointer-down lands outside the close button's frame | The tab is selected; close is not triggered |
| tab-bar-view-030 | accessibility-press-always-selects | An assistive-technology press is performed while the assistive cursor is conceptually "over" the close child | The tab is selected (never the close action); the press reports success |
| tab-bar-view-031 | tab-button-is-accessible-element | A tab button is constructed with title "Notes", highlighted state left at its default (not highlighted) | It exposes itself as a single accessibility element with a button role; its accessibility title reads "Notes"; its accessibility value reads `false` |
| tab-bar-view-032 | tab-button-title-updates-accessibility | The tab button's title is set to "Renamed" | The visible title text reads "Renamed"; the accessibility title reads "Renamed" |
| tab-bar-view-033 | tab-button-highlight-updates-accessibility-value | The tab button's highlighted state is set to `true` | The accessibility value reads `true`; the tab restyles to its selected appearance (see vectors 036-037) |
| tab-bar-view-034 | close-button-republished-as-sole-child | The tab button's accessibility children are queried | Returns a list containing exactly the close button |
| tab-bar-view-035 | close-button-carries-per-tab-identifier | A tab button is constructed for a given id | The tab button's own accessibility identifier reads `tab-bar.select.<id>`; the close button's reads `tab-bar.close.<id>` |
| tab-bar-view-036 | selecting-a-tab-restyles-its-button | The tab button's highlighted state is set to `true` | The tab's background fills with the `selection` color; its title's color role becomes `selectionText`; its close icon's tint becomes `selectionText` |
| tab-bar-view-037 | selecting-a-tab-restyles-its-button | The tab button's highlighted state is set to `false` | The tab's background becomes transparent; its title's color role becomes `secondaryText`; its close icon's tint becomes `tertiaryText` |
| tab-bar-view-038 | declares-reorder-callback | A new bar is constructed | Its reorder notification is a settable, externally observable property |
| tab-bar-view-041 | vertical-edge-cards-overlap-and-order-by-distance | A left-edge bar, 3 hosted items at indices 0,1,2; index 1 selected | Between the tied depth-1 neighbors (indices 0 and 2), index 0's wrapper view ends up more frontmost than index 2's, per the descending-index tie-break; index 1 (depth 0, selected) is frontmost of all three |
| tab-bar-view-042 | bar-never-fires-reorder | A bar with three items; the user clicks a tab, presses its close control, and drags a tab toward a new position | Select and close fire; the reorder notification never fires |
| tab-bar-view-043 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

