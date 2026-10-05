
- **load-directory-children**: Component MUST load the immediate children of
  the directory at initialization and MUST use that list as both the
  unfiltered entry list and the initial filtered list.
- **fixed-content-size**: Component MUST size the popover's content to
  280×320 points at initialization.
- **filter-placeholder-text**: The filter field MUST display the placeholder
  text "Filter" when empty.
- **filter-updates-immediately**: Component MUST re-run filtering on every
  keystroke in the filter field, without waiting for the user to finish
  typing or press Return.
- **filter-by-name-match**: Component MUST filter entries to only those whose
  name contains at least one case-insensitive, diacritic-sensitive substring
  occurrence of the current filter text — a literal substring search, not a
  prefix-only or fuzzy/subsequence match.
- **show-all-entries-when-filter-empty**: Component MUST show all loaded
  entries when the filter text is empty.
- **select-first-row-on-load**: Component MUST select the first row of the
  table immediately after the initial data load.
- **reselect-first-row-after-filter**: Component MUST reselect the first row
  of the table every time the filter is applied.
- **bold-matched-characters**: Component MUST render, in a bold system font,
  the character ranges of each entry's name that match the current filter
  text, and MUST render the remaining characters in a regular system font of
  the same size.
- **reject-empty-selection**: The table MUST NOT permit an empty selection.
- **reject-multiple-selection**: The table MUST NOT permit selecting more
  than one row at a time.
- **clamp-selection-to-list-bounds**: Component MUST clamp any requested
  selection index to the range from 0 to one less than the number of
  currently filtered entries.
- **no-op-selection-when-empty**: Component MUST NOT change selection when
  the filtered list is empty.
- **scroll-selection-into-view**: Component MUST scroll the table so a newly
  selected row is visible whenever selection changes programmatically.
- **relative-selection-movement**: Component MUST move the selection by a
  given relative offset from the current selection when instructed to do so,
  treating an absent selection as index 0.
- **arrow-keys-move-selection**: While the filter field has keyboard focus,
  the Down and Up arrow keys MUST move the table selection by a relative
  offset of +1 and -1 respectively (see relative-selection-movement), for as
  long as the view remains on screen.
- **return-key-chooses-selection**: While the filter field has keyboard
  focus, Return MUST perform the choose action on the current selection (see
  open-selected-file, ignore-directory-choice,
  ignore-choose-without-valid-selection).
- **focus-filter-field-on-appear**: Component MUST give the filter field
  keyboard focus when the view appears.
- **escape-key-cancels**: For the entire time the view is visible — from
  when it appears until it is about to disappear — Escape MUST trigger the
  cancel action (see invoke-cancel-callback-when-set, no-op-cancel-when-unset)
  regardless of which control has keyboard focus, and MUST NOT trigger it
  once the view has disappeared.
- **double-click-chooses-row**: Double-clicking a row MUST perform the same
  choose action as invoking choose through the keyboard.
- **open-selected-file**: Choosing a row MUST invoke the selection callback
  with the selected entry's URL only when that entry is a file.
- **ignore-directory-choice**: Choosing a row whose entry is a directory MUST
  NOT invoke the selection callback.
- **ignore-choose-without-valid-selection**: Choosing MUST NOT invoke the
  selection callback when there is no valid selected row index.
- **invoke-cancel-callback-when-set**: Component MUST invoke the cancel
  callback when keyboard navigation reports cancel and the cancel callback
  has been set.
- **no-op-cancel-when-unset**: Component MUST have no observable effect from
  a cancel when the cancel callback has not been set.
- **reuse-row-views**: Component MUST reuse a previously constructed row view
  for the table's column when one is available, constructing a new row view
  only when none exists yet, rather than always constructing a new one on
  reload.
- **truncate-row-label-middle**: The row label MUST truncate overflowing text
  in the middle.
- **single-column-table**: The table MUST present exactly one column.
- **no-column-header**: The table MUST NOT display a column header.
- **no-decoded-initialization**: Component MUST NOT support construction from
  a serialized/decoded representation (such as a saved interface file) and
  MUST fail fast if such construction is attempted.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

