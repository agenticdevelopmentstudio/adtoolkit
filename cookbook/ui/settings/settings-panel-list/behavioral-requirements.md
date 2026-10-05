
- **panel-storage**: Setting the panel list MUST store the given array as
  the component's full, ordered panel list, replacing whatever was stored
  before.
- **panel-set-rebuild**: Setting the panel list MUST rebuild the sidebar's
  sections from the newly stored array before returning.
- **unchanged-query-guard**: Assigning the search query a value equal to
  its current value MUST NOT trigger a section rebuild.
- **query-change-rebuild**: Assigning the search query a value different
  from its current value MUST trigger a section rebuild.
- **empty-query-inclusion**: A search query that is empty, or contains only
  whitespace/newline characters, MUST include every stored panel among the
  visible rows.
- **all-terms-match**: A non-empty, non-whitespace search query MUST
  include a panel only if every one of its space-separated terms is found,
  case-insensitively, as a substring of that panel's searchable text
  (harvested from the descriptor's title, section, search keywords, help
  content's topic titles and bodies, and — once the panel's own view has
  loaded — the visible titles of its own non-editable controls).
- **panel-order-preservation**: Visible rows MUST appear in the same
  relative order as their panels in the array most recently set.
- **contiguous-section-grouping**: Panels MUST be grouped into sidebar
  sections by contiguous run of equal descriptor-section value among the
  panels the current query admits; a panel whose section differs from the
  immediately preceding admitted panel's section MUST start a new section,
  even when an earlier, non-adjacent panel already used that same section
  title.
- **descriptor-row-mapping**: Each row's title, icon, and
  disabled-appearance flag MUST be read from that panel's descriptor
  title, icon, and disabled flag, respectively, at the moment sections are
  rebuilt.
- **original-index-row-id**: Each row's identifier MUST be the string form
  of its panel's zero-based index in the full array most recently set,
  independent of that row's position under the current filter.
- **selection-callback-bridge**: Once constructed through its normal
  construction path, the component MUST invoke its selection callback with
  the panel resolved from the newly selected row's identifier whenever the
  underlying selection changes, and MUST invoke that callback with no panel
  when the selection is cleared.
- **callback-free-selection**: Selecting a panel by index MUST select the
  row identified by the given index without invoking the selection
  callback.
- **out-of-range-select-guard**: Selecting a panel by index MUST have no
  effect when the index falls outside the panel list's bounds.
- **panel-visibility-report**: Querying whether a panel is visible MUST
  return true if, and only if, the panel at the given index is among the
  panels the current search query admits.
- **visible-index-report**: Querying the visible panel indices MUST return
  the original-array indices of the panels the current search query
  admits, in ascending order.
- **row-id-panel-resolution**: Resolving a panel from a row's identifier
  MUST parse that identifier as an integer and MUST yield no panel when
  the identifier is not a valid integer or falls outside the panel list's
  bounds.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

