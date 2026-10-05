
- **Decision**: Identify each row by the panel's original index in the
  full, unfiltered array, rather than by its position in the currently
  filtered list.
  **Rationale**: Per the source's own doc comment, "the position is the
  row's identity, so a filtered row still selects the panel it names" — a
  stable id under filtering is what lets index-based selection, visibility
  querying, and the hosting split view's arrow-key stepping keep working
  correctly while a search query is active.
  **Approved**: pending
- **Decision**: Group panels into sections by contiguous run of matching
  section value, rather than by collecting every panel that shares a
  section title regardless of position.
  **Rationale**: Per the source's own comment, "Sections come out in the
  order the panels arrive, and a run of panels sharing one section title
  is one section. Grouping by title across the whole list instead hoisted
  every unsectioned panel to the top of the sidebar, silently reordering a
  list whose author had already put it in the order they meant."
  **Approved**: pending
- **Decision**: Filter the sidebar in place (hiding non-matching rows)
  instead of replacing it with a separate search-results list.
  **Rationale**: Per the source's own doc comment, "Filtering the sidebar
  (rather than replacing it with a results list) is what keeps a search
  reversible: the row the user is reading stays where it was in the list,
  and deleting the query puts its neighbours back around it."
  **Approved**: pending
- **Decision**: Expose a visibility query as a separate operation rather
  than having index-based selection silently clear the search query
  whenever the target row is currently filtered out.
  **Rationale**: Per the source's own doc comment, "clearing the search on
  the caller's behalf when it was not needed throws away a filter the user
  is still reading by" — the caller (the settings split view) is expected
  to check visibility first and decide for itself whether to clear the
  query.
  **Approved**: pending
- **Decision**: Selecting a panel by index never invokes the selection
  callback.
  **Rationale**: Per the source's own doc comment, "programmatic selection
  flows through the hosting split view's own selection method" (the
  comment predates a rename and still names an older type, but the
  hosting split view is the only caller in source that drives index-based
  selection), so the callback exists only to report a user-driven row
  pick, not to echo back a selection the caller itself just made.
  **Approved**: pending
- **Decision**: Declare the component `open`, letting a host app subclass
  it to customize row presentation or add secondary actions, rather than
  sealing it or exposing customization through composition only. (AppKit.)
  **Rationale**: Per the source's own doc comment, "Open so client apps can
  customize row presentation or add secondary actions."
  **Approved**: pending

