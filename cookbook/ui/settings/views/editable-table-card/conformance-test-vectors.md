
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editable-table-card-001 | columns-in-declared-order | Declare path, rate and on columns | Three columns in that order with their titles |
| editable-table-card-002 | sort-reports-only | Click a sortable header | The sort callback receives the column id and direction and rows keep their order |
| editable-table-card-003 | empty-message | Set no rows, then rows | Message and hidden header, then the reverse |
| editable-table-card-004 | toggle-cells-report | Flip a toggle cell in row r2 | The callback receives r2, the column id and the new state |
| editable-table-card-005 | text-edit-reports-new-text | Commit the text $150 in the rate column of r1 | The edit callback receives r1, rate and $150 |
| editable-table-card-006 | unchanged-edit-is-not-reported | End an edit without changing the text | Nothing is reported |
| editable-table-card-007 | edit-binds-to-its-row-and-column | Type, then reload so the row moves, then commit | The edit is reported against the original row |
| editable-table-card-008 | edit-binds-to-its-row-and-column | Drag a column header and commit an edit | The edit is reported under the column it was typed into |
| editable-table-card-009 | gone-or-unknown-edits-are-dropped | Delete the row under a live field and commit | Nothing is reported |
| editable-table-card-010 | reload-held-while-editing | Begin editing, reload with other rows, then commit | The old rows stay until the commit, then the reload shows |
| editable-table-card-011 | close-releases-held-reload | Hold a reload and close the window | The held reload is applied |
| editable-table-card-012 | typed-day | Edit the day, start, hours and rate cells with valid text | Typed values for each are reported and none rejected |
| editable-table-card-013 | unparseable-edit-is-rejected | Enter text that is not a day, hours or amount | Each is rejected and none reported |
| editable-table-card-014 | typed-money | Blank a money cell that allows blanks | The edit reports no amount |
| editable-table-card-015 | read-only-rows-reject-edits | Edit any cell of a read-only row | The edit is rejected and nothing is reported as an edit |
| editable-table-card-016 | update-rows-in-place | Update row b with new values | Only b changes; order and selection are kept |
| editable-table-card-017 | update-rows-in-place | Update an id the table does not have | False and no rows change |
| editable-table-card-018 | selection-by-id | Select b, then select a missing id | True then false, selection stays on b |
| editable-table-card-019 | remove-follows-selection | Create the card, then select a row | Add enabled with remove disabled, then remove enabled |
| editable-table-card-020 | selection-reports-are-deduplicated | Select r1 then clear | Reports r1 then nil |
| editable-table-card-021 | footer-accessories | Open a footer menu button | It is a pull-down whose items are rebuilt on open |
| editable-table-card-022 | flagged-rows-are-marked | Flag a row | Its row view is marked flagged |
| editable-table-card-023 | views-are-recycled | Scroll through many rows | Distinct row views are fewer than half the rows seen |
| editable-table-card-024 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

