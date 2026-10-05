
- **Null/empty input**: No rows shows the empty message; a blank money cell is a no-amount edit only where blanks are allowed.
- **Boundary values**: Range limits on duration and money are inclusive; the visible row count only sizes the table.
- **Concurrent access**: Main thread only; an edit and a reload arriving together are ordered by holding the reload.
- **Error states**: Unparseable, out-of-range and read-only edits go to the rejected-edit callback; no message is shown.
- **Offline/disconnected state**: Not applicable.
- **Header drag**: Edits stay with the column they were typed into after columns are reordered.
- **Mismatched cell**: A cell value of the wrong kind draws nothing instead of failing.

