
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| breadcrumb-popover-001 | load-directory-children | Initialize with a directory containing files "A.txt", "B.txt" and subdirectory "C" | The table shows exactly 3 rows, one per loaded entry, in that order, before any filter text is entered |
| breadcrumb-popover-002 | fixed-content-size | Read the popover's content size immediately after initialization | 280×320 points |
| breadcrumb-popover-003 | filter-placeholder-text | Inspect the filter field before any input | Its placeholder text is "Filter" |
| breadcrumb-popover-004 | filter-updates-immediately, filter-by-name-match | Entries "Apple.txt" and "Banana.txt" loaded; type "app" into the filter field | Table reloads to show only "Apple.txt" (the only name with a case-insensitive substring match for "app") before any further keystroke or Return is pressed |
| breadcrumb-popover-005 | show-all-entries-when-filter-empty | Filter field contains "a" and is then cleared to `""` | Table shows all originally loaded entries again |
| breadcrumb-popover-006 | select-first-row-on-load | Component finishes loading with 3 entries | Row 0 is selected |
| breadcrumb-popover-007 | reselect-first-row-after-filter | Row 2 is selected; user types a filter that matches multiple entries | Row 0 of the newly filtered list is selected |
| breadcrumb-popover-008 | bold-matched-characters | Filter field contains "ap"; an entry's name is "Apple.txt" | The name's displayed text carries bold styling for the "Ap" range; the remaining characters carry regular styling |
| breadcrumb-popover-009 | reject-empty-selection, reject-multiple-selection | Inspect the table's configuration after it loads | Empty selection is disallowed and multiple selection is disallowed |
| breadcrumb-popover-010 | clamp-selection-to-list-bounds | 3 filtered entries; request selecting index -5, then index 999 | First request selects row 0; second request selects row 2 |
| breadcrumb-popover-011 | no-op-selection-when-empty | Filter text matches no entries; request moving the selection by +1 | No row is selected and no index-out-of-range error occurs |
| breadcrumb-popover-012 | scroll-selection-into-view | Selection moves to a row currently scrolled out of view | The row scrolls into view and becomes visible |
| breadcrumb-popover-013 | relative-selection-movement | 5 filtered entries; row 1 is selected; request moving the selection by +2 | Row 3 becomes selected |
| breadcrumb-popover-014 | arrow-keys-move-selection | View has appeared with 3 entries and row 0 selected; filter field has keyboard focus; the Down arrow key is pressed twice | Row 2 becomes selected (see relative-selection-movement) |
| breadcrumb-popover-015 | focus-filter-field-on-appear | View appears | The filter field is focused |
| breadcrumb-popover-016 | escape-key-cancels | The cancel callback is set; Escape is pressed while the view is visible; the view then disappears and Escape is pressed again | The first Escape invokes the cancel callback exactly once; the second Escape, after the view has disappeared, has no effect |
| breadcrumb-popover-017 | return-key-chooses-selection | Filter field has keyboard focus; the selected row is a file "Notes.txt"; Return is pressed | The selection callback is invoked exactly once with "Notes.txt"'s URL (see open-selected-file) |
| breadcrumb-popover-018 | double-click-chooses-row | User double-clicks a row representing a file | The selection callback is invoked with that file's URL — the same outcome as choosing it through the keyboard |
| breadcrumb-popover-019 | open-selected-file | Selected row is a file "Notes.txt"; choose is invoked | The selection callback is called exactly once, with "Notes.txt"'s URL |
| breadcrumb-popover-020 | ignore-directory-choice | Selected row is a subdirectory; choose is invoked | The selection callback is NOT called |
| breadcrumb-popover-021 | ignore-choose-without-valid-selection | The current filter text matches no entries, so the table shows zero rows; Return is pressed | The selection callback is NOT called |
| breadcrumb-popover-022 | invoke-cancel-callback-when-set | The cancel callback has been set; keyboard navigation reports cancel (Escape) | The cancel callback is invoked exactly once |
| breadcrumb-popover-023 | no-op-cancel-when-unset | The cancel callback is unset; keyboard navigation reports cancel (Escape) | No callback fires and no crash occurs |
| breadcrumb-popover-024 | reuse-row-views | The same 3 entries are shown, then the filter is applied and cleared twice in a row, forcing repeated table reloads | No more than one row view per visible row position is ever constructed; already-constructed views are reused across the reloads and only their displayed text changes |
| breadcrumb-popover-025 | truncate-row-label-middle | Row label text is longer than the 248pt column width | The label truncates the overflow in the middle |
| breadcrumb-popover-026 | single-column-table, no-column-header | Inspect the table after it loads | Exactly one column (identifier `"breadcrumb.entry"`) exists and no header is shown |
| breadcrumb-popover-027 | no-decoded-initialization | Attempt construction from a serialized/decoded representation | The call fails fast (a fatal/trap error); no instance is returned |
| breadcrumb-popover-028 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

