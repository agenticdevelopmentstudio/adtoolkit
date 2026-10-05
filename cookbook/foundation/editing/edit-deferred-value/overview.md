
A replacement value that must wait while an in-place edit is in flight. A table that edits its cells in place cannot swap its rows out from under a live field editor: the replacement lands before the table reloads, and the end of the edit then reads the new rows at the field's old index. So a reload that arrives mid-edit is parked here and handed back when the edit ends. It is one type rather than a flag and an optional per table, so a fix to when a held reload is released reaches every table built this way.

