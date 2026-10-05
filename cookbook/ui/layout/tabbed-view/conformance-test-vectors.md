
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| multi-tabbed-001 | top-edge-enabled-by-default | Construct a new view | The top edge is enabled; the right, bottom, and left edges are disabled |
| multi-tabbed-002 | edge-toggle-updates-bar-visibility | View loaded; enable the bottom edge | The bottom edge's tab bar becomes visible (no longer hidden) in the view hierarchy; the edge layout is rebuilt |
| multi-tabbed-003 | hidden-edge-retains-tabs | Add a tab on the bottom edge; disable the bottom edge; re-enable it | The bottom edge's tabs are unchanged throughout, and its button reappears once re-enabled |
| multi-tabbed-004 | edge-state-change-triggers-fallback-activation | Active tab lives on the top edge; disable the top edge | Fallback activation runs; the active tab changes (to another tab or none) |
| multi-tabbed-005 | disabled-edge-excluded-from-layout | The left edge is disabled | The content area's leading edge is pinned directly to the view's own leading edge, not to the left bar (which is hidden and unconstrained) |
| multi-tabbed-006 | bar-spans-content-perpendicular-dimension | The top edge is enabled | The top bar spans the full width of the content area: its leading and trailing edges align with the content area's leading and trailing edges |
| multi-tabbed-007 | add-tab-appends-to-edge | Edge already has 2 tabs; add a new tab to it | The new tab is now last in that edge's tab list |
| multi-tabbed-008 | insert-tab-clamps-index | Edge has 2 tabs; insert a tab at index 99 | The tab is inserted at index `2` (the end), not out of bounds |
| multi-tabbed-009 | remove-tab-locates-owning-edge | Tab lives on the right edge; remove it by id with no edge argument | The right edge's tabs no longer contain it |
| multi-tabbed-010 | move-tab-clamps-index-within-edge | Edge has 3 tabs; move the first tab to index 50 | The tab moves to index `2` (the last valid index) |
| multi-tabbed-011 | move-tab-no-op-when-index-unchanged | Tab already at index `1`; move it to index `1` | The tab list order is unchanged; the reorder notification is not invoked |
| multi-tabbed-012 | rename-tab-title-items-only | Rename a content-hosting tab | The tab's displayed title is unchanged |
| multi-tabbed-013 | set-tab-item-preserves-mounted-content | Replace the active tab's item | The tab's content (and, if it is the active tab, the mounted center content) is unchanged |
| multi-tabbed-014 | single-active-tab-invariant | Tabs exist on 2 enabled edges with unrelated groups; select a tab on the top edge, then select a different (ungrouped) tab on the left edge | After the second selection, the active tab names only the left edge's tab; the top bar shows no tab as selected |
| multi-tabbed-015 | tab-defaults-to-own-group | Create a tab with no group id | The tab's group id equals its own id |
| multi-tabbed-016 | group-siblings-share-selection-across-edges | Top and bottom tabs share a group id; select the bottom one | The top bar shows its own member of the group as selected, even though the bottom tab is the one whose content is shown |
| multi-tabbed-017 | ungrouped-tab-shows-no-selection-on-other-edges | The top tab has no shared group with any bottom tab; select the top tab | The bottom bar shows no tab as selected |
| multi-tabbed-018 | first-tab-on-enabled-edge-auto-activates | Edge has no tabs and is enabled; add a tab to it | The added tab becomes active |
| multi-tabbed-019 | active-tab-removal-neighbor | Active tab at index 1 of 3 on its edge is removed | The tab now at index 1 (the old index 2) becomes active |
| multi-tabbed-020 | removing-last-tab-on-edge-triggers-fallback | Active tab is the only tab on its edge; remove it | Fallback activation runs |
| multi-tabbed-021 | fallback-prefers-active-group | Active tab's group has a sibling on another enabled edge; a tab unrelated to the group sits first on the first enabled edge | Fallback activates the group sibling, not the unrelated first tab |
| multi-tabbed-022 | fallback-clears-when-nothing-found | No enabled edge has any tab; fallback runs | The active tab is now none |
| multi-tabbed-023 | active-tab-change-notification | The last tab on the last enabled edge is removed | The delegate is notified of an active-tab change with no tab and no edge |
| multi-tabbed-024 | select-tab-refuses-non-member-id | Select an id that is not in the given edge's tabs | The active tab is unchanged |
| multi-tabbed-025 | center-shows-active-tab-content | A tab is activated | The shared content area mounts the active tab's content as its sole child view |
| multi-tabbed-026 | center-falls-back-to-main-content | No tab active; a main content is designated | The shared content area mounts that main content's view |
| multi-tabbed-027 | center-mount-skips-redundant-remount | Center content is refreshed twice in a row with the same resolved target | The mounted content's view is not removed and re-added on the second call |
| multi-tabbed-028 | content-insets-applied-to-mounted-view | Content insets set to `4` on every side | The mounted content sits 4pt in from the content area's top and leading edges, and 4pt in from its bottom and trailing edges (inset inward) |
| multi-tabbed-029 | center-outline-reflects-color-override-or-fallback | No outline-color override set | The content area's visible border renders in the theme's `outline` color |
| multi-tabbed-030 | preferred-content-size-change-refreshes-every-bar | Hosted content on the left edge changes its preferred size and reports the change | Every edge's bar — not only the left edge's — recalculates its thickness to reflect its own hosted items' current preferred size |
| multi-tabbed-031 | tab-bar-orientation-follows-edge | A right-edge tab bar is built | The right bar lays out its items down a vertical column, not across a row |
| multi-tabbed-032 | tab-bar-thickness-floor-and-growth | The left bar hosts an item with a preferred width of `200` | The left bar's thickness (frame width) grows to `206pt` (200 + 6pt padding), above its `140pt` floor |
| multi-tabbed-033 | tab-item-padding-flush-to-content-side | A top bar is built | The top bar's first item sits `6pt` from the bar's outer (top) edge; on the workspace-facing (bottom) edge, items sit flush with a `0pt` gap |
| multi-tabbed-034 | tab-button-selection-style | A tab button is set highlighted | The selected tab's background fills with the `selection` palette color, and its title text switches to the `selectionText` role |
| multi-tabbed-035 | hosted-item-highlight-follows-selection | A content-hosting tab that supports highlight reporting is selected | Its highlighted state reads `true` |
| multi-tabbed-036 | close-icon-hit-region | A pointer-down lands inside the close button's frame | The close action fires, closing that tab; the click does not also select the tab |
| multi-tabbed-037 | clicking-hosted-item-selects-its-tab | A real pointer-down is hit-tested onto a hosted item's interior label | The hosted tab becomes selected |
| multi-tabbed-038 | vertical-edge-cards-overlap-and-order-by-distance | The left bar has 3 hosted items; the middle one is selected | The middle item's neighbors are drawn and hit-tested behind it: it visually overlaps and receives clicks over both neighbors |
| multi-tabbed-039 | cross-edge-move-preserves-foreign-content | A hosted content is moved from the left bar to the right bar (insert-then-remove); the left bar reconciles afterward | The content's parent and mounted view are unaffected by the left bar's reconciliation |
| multi-tabbed-040 | new-tab-hook-delegates-without-mutating | Request a new tab with a delegate installed | The delegate's new-tab-needed notification is invoked; no tab is added by this call itself |
| multi-tabbed-041 | explicit-group-override | Create two tab instances with the same explicit group id, one per edge; select one | The other tab, sharing the same group id, is also shown as selected on its own edge's bar |
| multi-tabbed-042 | Null/empty input (Edge Cases) | Query the tabs for an edge with no tabs ever added | Returns an empty list, without trapping |
| multi-tabbed-043 | Error states (Edge Cases) | Set a delegate, then let it deallocate (no strong reference remains); remove the last tab on an edge | The tab is removed from that edge's tabs (the mutation completes); no crash occurs even though the delegate reference is now empty |
| multi-tabbed-044 | first-tab-on-enabled-edge-auto-activates | Edge has no tabs and is enabled; insert a tab at index 0 directly (not the append operation) | The inserted tab becomes active |
| multi-tabbed-045 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

