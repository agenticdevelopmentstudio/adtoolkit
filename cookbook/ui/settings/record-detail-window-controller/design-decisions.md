
**Decision**: The window never creates or deletes a record; it reports add and remove to the owner, who changes the model and pushes the list back.
**Rationale**: The source's add and remove callbacks say the owner creates the record and calls set-records, which keeps the model in one place at the cost of every owner wiring both callbacks.
**Approved**: pending

**Decision**: Panes are keyed by record id and reused across pushes, rather than rebuilt.
**Rationale**: The source comments say the split restores selection by panel identity across a rebuild, so reusing the objects is what keeps the selected row selected; ids are database ids, not row numbers, because positions change on every push.
**Approved**: pending

**Decision**: The sidebar keeps the owner's order and does not sort by title.
**Rationale**: The source sets title sorting off because rows are renameable and an alphabetical sidebar moves the row from under the cursor mid-edit; the owner sorts once, where it can also place a catch-all row last.
**Approved**: pending

**Decision**: Catch-all rows are fixed panels, never records.
**Rationale**: The source says a built-in row such as Unassigned belongs in the fixed panels, which are never removable and never passed to the record callbacks, rather than in the records.
**Approved**: pending

**Decision**: Selection is announced only on a real change, and synced directly on select rather than through the navigation notification.
**Rationale**: The source guards the select callback on a change so a timer-driven reload does not re-announce, and syncs directly because the navigation closure is wired only once the window has loaded, so an unshown window would otherwise keep a stale selection.
**Approved**: pending

