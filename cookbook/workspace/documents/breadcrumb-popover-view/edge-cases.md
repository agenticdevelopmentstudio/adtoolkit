
- Null/empty input (MUST): the directory reference and the selection
  callback are non-optional, required initializer parameters, so the type
  system rules out an absent value for either; the component provides, and
  needs, no nil-handling path for them. A directory whose immediate contents
  are empty yields an empty entry list and an empty filtered list; the table
  shows zero rows and selection changes are no-ops.
- Boundary values (MUST): selecting an index clamps it to the valid range of
  the filtered list — e.g. selecting index -5 with 3 filtered entries
  selects row 0, and selecting index 999 selects row 2. Moving the selection
  by a relative offset reuses the same clamp, so moving far past either end
  of the list settles on the nearest boundary row rather than wrapping or
  erroring.
- Concurrent access: Not applicable — the component confines all reads and
  writes of its entry lists and UI to a single execution context, enforced
  by the platform's concurrency checker; source provides no path for two
  threads to mutate this component's state simultaneously.
- Error states (MUST): loading the directory's children is called
  synchronously and cannot fail in this component; its return value is
  assigned to the entry lists unconditionally, with no error branch anywhere
  in source. The component performs no validation or error handling of its
  own on this call; whatever the load returns — including an empty list, if
  that is how it represents an unreadable directory — is treated identically
  to a directory with no children. Any error handling for an unreadable
  directory is the loading operation's own responsibility, and its
  implementation is outside the given source.
- Offline/disconnected: Not applicable — the component reads only the local
  file system; source contains no network call.
- Directory rows are inert (MUST): choosing a directory row does nothing;
  only files can be opened from here. The choose action is guarded so it has
  no effect for a directory entry — Return, double-click, and any other
  route to choosing all have the same no-op outcome for a directory row.
- No empty-results messaging (MUST): When the current filter matches zero
  entries, the table renders zero rows with no placeholder text, icon, or
  "no results" view; source defines no empty-state UI for this case.
- Cancel callback set after construction (MUST): the cancel callback is
  documented as set by the breadcrumb view after construction, since only it
  owns the popover. If Escape is pressed before the owning breadcrumb view
  has assigned the callback, the call is silently a no-op — the popover does
  not close through this path.

