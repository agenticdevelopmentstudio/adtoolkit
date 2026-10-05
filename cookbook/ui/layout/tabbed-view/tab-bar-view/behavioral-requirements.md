
- **thickness-floor-by-edge**: The bar's preferred thickness MUST be `28pt`
  for a top/bottom bar and `140pt` for a left/right bar. These are fixed
  constants with no stated rationale beyond a sensible default; a port
  SHOULD treat them as theme-tunable rather than hardcoding them verbatim.
- **orientation-follows-edge**: The bar MUST lay out its arranged content
  horizontally for a top/bottom bar and vertically for a left/right bar.
- **alignment-favors-workspace-side**: The bar MUST align its arranged
  content to the side of the bar adjacent to the workspace/content area it
  frames: the bottom for a top bar, the top for a bottom bar, the trailing
  edge for a left bar, and the leading edge for a right bar.
- **item-spacing-by-orientation**: The bar MUST set the gap between arranged
  items to `4pt` when it is horizontal and to `-16pt` (a negative gap) when
  it is vertical; the vertical overlap makes the column read as a deck being
  turned rather than a list, while a horizontal bar has room along its
  length and does not need it.
- **start-inset-defaults-to-end-padding**: The bar's start inset MUST
  default to `8pt` and MUST re-apply the bar's edge insets whenever it is
  changed.
- **host-may-override-start-inset**: A host MAY set the start inset to a
  value other than the default, to line a bar's first item up with chrome
  outside the bar; the bar itself has no opinion on what that chrome is.
- **outer-padding-on-window-side-only**: The bar MUST apply `6pt` of inset
  on its outer (window) side and `0pt` on its workspace side, with the start
  inset applied at the bar's start (along its length) and `8pt` at its end.
- **bar-fills-perpendicular-and-pins-length**: For a top/bottom bar, the bar
  MUST pin its arranged content's top, leading, trailing, and bottom edges to
  its own corresponding edges and hold a fixed height matching its
  thickness; for a left/right bar, MUST pin its arranged content's top,
  leading, and trailing edges to its own, hold a fixed width matching its
  thickness, and constrain its arranged content's bottom edge to be no
  farther down than its own bottom (not pinned exactly).
- **vertical-bar-packs-from-top**: On a left/right bar, unused column height
  below the arranged content MUST remain empty rather than stretching the
  arranged items, as a direct consequence of the inequality-only bottom
  constraint described in **bar-fills-perpendicular-and-pins-length**.
- **bar-fills-window-background**: The bar MUST paint its own background
  with the `windowBackground` palette role and MUST repaint it whenever the
  resolved theme palette changes.
- **set-items-triggers-rebuild**: Setting the bar's items MUST store the
  given items and selected id and MUST rebuild the bar's arranged content to
  match them.
- **set-selected-restyles-and-reorders**: Setting the selected tab MUST
  update the bar's selected id, MUST set the highlighted state to `true` on
  exactly the tab button and any hosted content that supports highlight
  reporting whose id equals the new selection, and to `false` on every
  other one, and MUST update every hosted item's reported stack depth and,
  on a vertical bar, its front-to-back order to match (see
  **stack-depth-by-distance-from-selection** and
  **vertical-edge-cards-overlap-and-order-by-distance**).
- **stack-depth-by-distance-from-selection**: A selection change MUST
  compute each item's depth as the absolute difference between its index
  and the selected item's index, or `1` for every item when nothing is
  selected, and MUST report that depth to any hosted content that supports
  stack-depth reporting.
- **vertical-edge-cards-overlap-and-order-by-distance**: On a left/right
  bar, a selection change MUST reorder each content-hosting item's wrapper
  view, deepest-first, so the item nearest the selection ends up frontmost
  in both z-order and hit-testing; ties in depth MUST be broken by
  descending index.
- **rename-title-item**: Renaming an item by id MUST set the matching
  item's payload to a title item with the new text and MUST update that
  id's tab button title when an item with the given id exists, and MUST be
  a silent no-op when no item has that id.
- **rebuild-clears-and-repopulates**: Setting new items MUST discard every
  previously rendered item's view and any per-item state associated with
  the old items before repopulating the bar from the new list.
- **cross-edge-move-preserves-foreign-content**: When reconciling hosted
  content, the bar MUST remove a superseded item's view from its superview
  and remove its parent relationship only when that view is still sitting
  in a wrapper this bar itself created; it MUST leave the view and parent
  relationship untouched when the view has already been reparented onto a
  different bar.
- **rebuild-drops-stale-hosted-content**: Setting new items MUST stop
  tracking a content-hosting item's hosted content whenever that id's
  current payload differs by identity from the previously hosted content
  (including when the id is no longer present in the new items at all),
  independent of whether **cross-edge-move-preserves-foreign-content** also
  tore down its view.
- **title-item-becomes-button**: For each title item, the bar MUST create a
  tab button, set its highlighted state to match the selected id, wire its
  select/close actions to the bar's own select/close callbacks, add it as
  an arranged item, and MUST additionally pin its cross-axis edges only
  when the bar's orientation is vertical.
- **content-item-becomes-hosted-view**: For each content-hosting item, the
  bar MUST add the content as a child of its host content when it is not
  already its parent, set its highlighted state and close action on it when
  it supports those hooks, wrap its view in a hosted-item wrapper wired to
  the bar's select callback, add that wrapper as an arranged item, and MUST
  pin the wrapper's cross-axis edges unconditionally (regardless of the
  bar's orientation).
- **thickness-grows-with-hosted-content**: The bar MUST set its thickness to
  the greater of its preferred thickness floor and (the largest hosted
  item's preferred size on the bar's thickness axis, plus `6pt`), and MUST
  recompute it whenever its items change.
- **host-view-fills-hosted-content**: The hosted-item wrapper MUST pin its
  wrapped content view's top, leading, trailing, and bottom edges to its own
  corresponding edges.
- **host-view-click-selects**: The hosted-item wrapper MUST select its tab
  for a click that lands on the wrapper itself, without intercepting a
  click an interior subview (such as a hosted item's own close control)
  already handles as the frontmost hit-tested view.
- **close-icon-hit-routes-to-close**: A tab button MUST route a pointer-down
  that lands within the close icon's own bounds to that icon's own native
  handling, and MUST NOT also select the tab in that case; it MUST select
  the tab for a pointer-down anywhere else in the view.
- **accessibility-press-always-selects**: An assistive-technology press on a
  tab button MUST always select the tab and report success, regardless of
  where the press targets the element — unlike a physical click, it never
  routes to the close action.
- **tab-button-is-accessible-element**: Creating a tab button MUST expose it
  as a single accessibility element with a button role, and MUST set its
  initial accessibility title and value from the given title text and
  highlighted state.
- **tab-button-title-updates-accessibility**: Setting a tab button's title
  MUST update both the visible title text and its accessibility title to
  the new value.
- **tab-button-highlight-updates-accessibility-value**: Setting a tab
  button's highlighted state MUST update its accessibility value to the new
  value and MUST restyle the button to match (see
  **selecting-a-tab-restyles-its-button**).
- **close-button-republished-as-sole-child**: A tab button's reported
  accessibility children MUST be exactly its close button, so the close
  control stays reachable in the accessibility tree once the tab button
  becomes a single accessibility element.
- **close-button-carries-per-tab-identifier**: Creating a tab button MUST
  give its close button the accessibility identifier `tab-bar.close.<id>`
  and MUST give the tab button itself `tab-bar.select.<id>`, both keyed by
  the tab's own id.
- **selecting-a-tab-restyles-its-button**: Selecting a tab MUST fill its
  background with the `selection` palette role, set its title's color role
  to `selectionText`, and set its close icon's tint to `selectionText` when
  highlighted; it MUST use transparent, `secondaryText`, and `tertiaryText`
  respectively when not highlighted.
- **declares-reorder-callback**: The bar MUST expose a reorder notification,
  in addition to its select and close notifications, for a caller to
  observe tab reordering.

- **bar-never-fires-reorder**: The bar MUST NOT invoke its reorder
  notification on its own: it provides no drag or keyboard interaction that
  determines a target index, so the notification is declared and forwarded by
  the owner but is only ever fired by the owner's own programmatic move
  operation, never by the bar. A caller sets a new order by supplying new
  items or by calling that move operation.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

