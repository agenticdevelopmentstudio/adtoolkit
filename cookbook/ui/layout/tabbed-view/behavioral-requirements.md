
- **top-edge-enabled-by-default**: The view MUST initialize with the top
  edge enabled and the right, bottom, and left edges disabled.
- **edge-toggle-updates-bar-visibility**: Once loaded, the view MUST update
  that edge's bar visibility to match its enabled state and rebuild the edge
  layout whenever an edge's enabled state is changed, and MUST do nothing (no
  state change, no layout rebuild) when the requested state already matches
  the edge's current state.
- **hidden-edge-retains-tabs**: The view MUST NOT discard a disabled edge's
  tab list; its tabs MUST still be reported for that edge and MUST reappear
  in that edge's bar once the edge is re-enabled.
- **edge-state-change-triggers-fallback-activation**: The view MUST run
  fallback activation when disabling the edge currently holding the active
  tab, and MUST also run it when enabling an edge while no tab is currently
  active.
- **disabled-edge-excluded-from-layout**: The view MUST pin the shared
  content area directly to the view's own edge, rather than to a hidden bar,
  for every disabled edge, and MUST leave a disabled edge's bar with no
  layout constraints connecting it to the content area.
- **bar-spans-content-perpendicular-dimension**: The view MUST constrain a
  top/bottom bar's leading and trailing edges to the content area's leading
  and trailing edges, and a left/right bar's top and bottom edges to the
  content area's top and bottom edges, so each bar spans the full width or
  height of what it frames.
- **add-tab-appends-to-edge**: Adding a tab MUST insert it at the end of the
  specified edge's tab list.
- **insert-tab-clamps-index**: Inserting a tab at a given index MUST clamp
  the requested index into the range from `0` to the edge's current tab
  count, rather than trapping or ignoring an out-of-range value.
- **remove-tab-locates-owning-edge**: Removing a tab by id MUST locate the
  edge that owns the given id itself (the caller does not name an edge) and
  remove the tab from that edge's list.
- **move-tab-clamps-index-within-edge**: Moving a tab to a given index MUST
  clamp the requested index into the range from `0` to one less than the
  edge's tab count, and MUST reorder the tab only within the edge given,
  never across edges.
- **move-tab-no-op-when-index-unchanged**: Moving a tab MUST leave the tab
  list unchanged and MUST NOT invoke the reorder notification when the
  clamped target index equals the tab's current index.
- **rename-tab-title-items-only**: Renaming a tab MUST update the displayed
  text of a tab whose item is a title, and MUST have no effect at all on a
  tab whose item hosts content.
- **set-tab-item-preserves-mounted-content**: Replacing a tab's item MUST
  replace only what the tab shows in its bar; it MUST NOT alter, remount, or
  otherwise disturb that tab's own content in the center area.
- **single-active-tab-invariant**: The view MUST have at most one active tab
  across the entire view, spanning all four edges, at any time.
- **tab-defaults-to-own-group**: Creating a tab MUST default its group id to
  its own id when no explicit group id is supplied.
- **group-siblings-share-selection-across-edges**: The view MUST show every
  tab that shares the active tab's group id as selected on its own edge's
  bar, even though only one of them is the tab whose content the center
  shows.
- **ungrouped-tab-shows-no-selection-on-other-edges**: The view MUST show no
  selection on an edge whose tabs include no member of the active tab's
  group.
- **first-tab-on-enabled-edge-auto-activates**: Inserting a tab MUST
  activate it when there is currently no active tab and the target edge is
  enabled.
- **active-tab-removal-neighbor**: Removing a tab MUST activate the tab left
  at the removed tab's clamped index on the same edge when the removed tab
  was active and tabs remain on that edge.
- **removing-last-tab-on-edge-triggers-fallback**: Removing a tab MUST run
  fallback activation when removing the active tab leaves its edge with no
  tabs left.
- **fallback-prefers-active-group**: Fallback activation MUST prefer a tab,
  on any enabled edge, that shares the previously active tab's group id,
  over the first tab of the first enabled edge.
- **fallback-clears-when-nothing-found**: Fallback activation MUST set the
  active tab to none when no enabled edge has any tab at all.
- **active-tab-change-notification**: The view MUST notify its delegate of
  the active-tab change with an empty id and edge, rather than skipping the
  notification, whenever the active tab is cleared.
- **select-tab-refuses-non-member-id**: Selecting a tab by id on a given
  edge MUST have no effect when the given id is not a member of that edge's
  own tab list (it MUST NOT search other edges).
- **center-shows-active-tab-content**: The view MUST mount the active tab's
  content as the sole child filling the shared content area.
- **center-falls-back-to-main-content**: The view MUST mount the designated
  main content in the shared content area whenever no tab is active, and
  MUST leave the area unmounted when both the active tab and the main
  content are absent.
- **center-mount-skips-redundant-remount**: The view MUST NOT tear down and
  remount the currently mounted content when refreshing center content
  resolves to the content already mounted (identity match).
- **content-insets-applied-to-mounted-view**: The view MUST offset the
  mounted content from the shared content area's edges by the four insets
  configured via content insets (top, leading, bottom, trailing).
- **center-outline-reflects-color-override-or-fallback**: The view MUST
  draw a `1pt` border around the shared content area using the configured
  outline-color override when it is set, and the theme's `outline` role when
  it is not.
- **preferred-content-size-change-refreshes-every-bar**: Whenever any hosted
  content reports a changed preferred size, every edge's bar — not only the
  bar hosting the changed content — MUST reflect its own hosted items'
  current preferred size in its thickness.
- **tab-bar-orientation-follows-edge**: A tab bar MUST lay out a top or
  bottom bar's items in a horizontal row and a left or right bar's items in
  a vertical column.
- **tab-bar-thickness-floor-and-growth**: A tab bar MUST size its thickness
  to at least `28pt` for a top/bottom bar or `140pt` for a left/right bar,
  and MUST grow it to the largest hosted item's preferred size on that axis
  plus `6pt` whenever that sum exceeds the floor.
- **tab-item-padding-flush-to-content-side**: A tab bar MUST apply `6pt` of
  padding between an item and the bar's outer (window) side, and MUST leave
  the content (workspace) side of the bar flush against its items with no
  padding.
- **tab-button-selection-style**: A tab button MUST fill a selected tab's
  background with the `selection` palette role and leave an unselected
  tab's background transparent, and MUST switch its label between the
  `selectionText` and `secondaryText` roles, and its close icon's tint
  between `selectionText` and `tertiaryText`, to match.
- **hosted-item-highlight-follows-selection**: The view MUST set a
  content-hosting tab's highlighted state to match the selection state,
  whenever the hosted item supports highlight reporting.
- **close-icon-hit-region**: A tab button MUST select the tab when a
  pointer-down lands outside the close button's frame, and MUST route a
  pointer-down inside the close button's frame to the close action instead
  of selecting.
- **clicking-hosted-item-selects-its-tab**: The hosted-item wrapper MUST
  select its tab when any point inside the hosted content is clicked,
  without preventing an interior control (such as the hosted item's own
  close control) from handling its own click first.
- **vertical-edge-cards-overlap-and-order-by-distance**: On a left or right
  edge, a tab bar MUST lay out content-hosting items with a `-16pt` overlap
  and MUST order them, back to front, by each item's distance (in index
  positions) from the currently selected item, so an item nearer the
  selection draws and is hit-tested above one farther away. (This ordering
  and the `-16pt` overlap spacing itself only apply to content-hosting
  items — see the Design Decisions entry on title-only tabs on a vertical
  edge.)
- **cross-edge-move-preserves-foreign-content**: When reconciling a bar's
  items, a tab bar MUST leave a hosted content's parent and mounted view
  untouched if that content's view has already been reparented onto a
  different bar's wrapper (a cross-edge move in progress), rather than
  tearing it down because its id is no longer present in this bar's own
  items.
- **new-tab-hook-delegates-without-mutating**: Requesting a new tab MUST
  forward to the delegate's new-tab-needed notification and MUST NOT itself
  add, remove, or otherwise mutate any tab.
- **explicit-group-override**: A caller MAY supply an explicit group id when
  creating a tab, differing from its own id, to tie multiple tab instances
  (typically one per edge) together as siblings of one logical tab.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

