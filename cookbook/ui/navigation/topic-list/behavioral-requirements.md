
- **group-items-by-section**: Component MUST render every section's items,
  in the order sections and items are given to the grouped setter, as leaf
  rows of a single flat list.
- **header-row-for-titled-section**: Component MUST render a group header
  row carrying the section's title for every section whose title is a
  non-empty string.
- **omit-header-for-untitled-section**: Component MUST NOT render a group
  header row for a section whose title is empty or unset - only a
  non-empty title produces a header node.
- **flat-row-hierarchy**: Component MUST report every row - header and
  item alike - as not expandable and MUST use no per-level indentation, so
  no row is ever indented or nested under another.
- **hide-disclosure-controls**: Component MUST hide each row's disclosure
  control.
- **hide-outline-column-header**: Component MUST disable the list's
  built-in column header bar, so it is never drawn above the rows.
- **header-rows-not-selectable**: Component MUST prevent a group header
  row from becoming selected; only an item row can be selected.
- **disabled-item-selectability**: Component MUST allow selecting an item
  marked disabled through exactly the same paths, and with exactly the
  same result, as an item that is not disabled - both the
  selection-gating check and an item row's accessibility press handler
  branch only on whether a row is a header or an item, never on whether
  the item is disabled.
- **mute-disabled-item-appearance**: Component MUST render an item marked
  disabled using the tertiary text color for both its label text and its
  icon tint, instead of the primary text color (label) and the accent
  color (icon tint) used for an enabled item.
- **render-item-without-icon-when-nil**: Component MUST render an item row
  whose icon is unset with no image in its image view.
- **user-selection-callback**: Component MUST invoke the selection
  callback with the newly selected item, or none if there is no selection,
  whenever the list's selection changes as a direct result of user
  interaction (i.e. outside any selection-suppression scope - see
  **suppress-onselect-on-programmatic-selection**).
- **suppress-onselect-on-programmatic-selection**: Component MUST NOT
  invoke the selection callback for a selection change made during a
  programmatic-selection scope - i.e. the reload-and-restore performed by
  the grouped setter and by a theme change, and the selection made by
  selecting an item by id.
- **select-item-by-id**: Selecting an item by id MUST select the row of
  the first item, in section/item order, whose id matches the given id,
  without firing the selection callback.
- **missing-id-selection**: Selecting an item by id MUST leave the current
  selection unchanged when no item's id matches the given id.
- **noop-select-already-selected-id**: Selecting an item by id MUST leave
  the current selection unchanged, and MUST NOT re-issue a selection
  command, when the matching row is already the selected row.
- **restore-selection-by-id-after-resection**: The grouped setter MUST
  re-select, by id, whichever item was selected immediately before the
  call, if an item with that id is still present in the new sections.
- **restore-selection-across-theme-change**: A theme change MUST preserve
  the list's selected row indexes across the reload it performs,
  re-selecting them when they differ afterward.
- **stable-row-node-identity**: Component MUST let the list resolve a
  given logical row to the same valid row across repeated accesses between
  one grouped-setter call and the next, rather than losing that identity
  (and failing to resolve) because a fresh row representation was
  constructed for that row on each access.
- **hide-header-when-title-and-accessory-empty**: Component MUST hide the
  title header view when the trimmed title is empty AND no header
  accessory view is set.
- **hide-footer-when-unset**: Component MUST hide the footer container
  when no footer view is set.
- **header-accessory-below-title**: When a header accessory view is set,
  component MUST lay it out directly below the title label, spanning the
  full width of the header area.
- **footer-spans-sidebar-width**: A footer view installed via the footer
  setter MUST have its leading, trailing, top, and bottom edges pinned to
  its container's, spanning the sidebar's full width.
- **content-below-titlebar-safe-area**: Component MUST keep its list
  content below the window's non-safe top inset (e.g. a full-height
  window's titlebar) by pinning its content's top edge to the root view's
  safe-area boundary rather than its plain top edge, while its
  leading/trailing/bottom edges match the root view's own edges.
- **preferred-width**: Computing the preferred width MUST return exactly
  the widest text-based candidate (the title's rendered width plus its own
  leading inset; each section header's rendered width plus its own
  leading inset; each item's rendered width plus its own chrome width;
  defaulting to 0 when there is no title, header, or item), plus a fixed
  chrome padding of 64pt (30 leading inset + 16 scroller gutter + 18
  trailing margin) - then MUST widen that further to at least the footer
  view's own fitting width (when a footer is set) and to at least the
  header accessory view's own fitting width plus the title's leading
  inset and the header's trailing inset (when an accessory is set). The
  footer and accessory floors are absolute widths, not added to the fixed
  chrome padding.
- **item-accessibility-id-from-title**: Component MUST set each item row's
  label accessibility identifier to a value derived from the item's
  **title** (slugified, and prefixed to namespace it to this component),
  not its id.
- **accessibility-press-selection**: An item row's label MUST respond to
  an accessibility press action by locating its row in the enclosing list
  and selecting it, and MUST first run the selection-gating check for that
  row and return failure without selecting when that check fails.
- **repaint-on-theme-change**: Component MUST update the background color
  of the root view, content stack, header view, and footer container, the
  title label's font and text color, and the scroll/list view background,
  to the newly observed theme palette's values every time a theme change
  is reported.
- **single-column-fills-width**: The list's one column MUST be resized to
  fill the list's available width on every layout pass, so no row ever
  clips its label regardless of when the enclosing view settles the
  sidebar's width.
- **overlay-autohide-scroller**: Component MUST configure the scroll view
  so its vertical scroller floats over content, appearing only while
  scrolling and while the list overflows, and hides itself otherwise.
- **automatic-outline-style**: Component MUST render the list with a
  theme-following material rather than a forced, fixed-appearance
  material, regardless of the active system appearance.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

