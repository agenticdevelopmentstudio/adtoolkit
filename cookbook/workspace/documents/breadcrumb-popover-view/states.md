
| State | Appearance change |
|-------|------------------|
| Default (unselected row) | Row label rendered at the small system font size; characters matching the current filter text are bold, the rest regular; no selection highlight. |
| Selected row | The platform's default row-selection highlight is applied; the row is scrolled into view. |
| Filtered (non-empty query) | Only entries whose name has at least one match for the current filter text are shown; matched characters render bold; row 0 of the new filtered list is reselected. |
| Empty result set | No rows are shown; selection changes become no-ops while the filtered list is empty. |
| Focused (filter field) | The filter field becomes focused when the view appears; source sets no other explicit focus-ring styling. |
| Disabled | Not applicable: no control in this component (filter field, table, rows) is ever disabled in source. |
| Loading | Not applicable: the directory's children are loaded synchronously at initialization; source defines no loading/pending state or indicator. |

