
- **Null/empty input**: Not applicable — the add-view operation's parameter
  is a non-optional view; the type system rejects a missing argument at
  compile time. The parameterless construction path and the frame-based
  construction path (whose argument is discarded, see Platform Notes) leave no other caller-supplied value that could be null or
  empty. Calling the add-view operation zero times is a valid,
  un-special-cased path: the internal stack view's arranged children stay
  empty and the component collapses to whatever intrinsic size an empty
  stack view resolves to.
- **Boundary values**: The standard group-spacing value (see
  **group-spacing**) is read exactly once, into the internal stack view's
  spacing property, at construction time. The settings-layout constants are
  observable for change, but the component never subscribes to updates, so
  if a caller mutates the underlying value after a component instance
  already exists, that instance's spacing does not update — it stays at
  whatever the group-spacing value was when it was constructed. This is the
  same staleness pattern documented for the sibling Divider View and
  Vertical Stack View wrappers.
- **Concurrent access**: Not applicable — the component is confined to the
  UI thread, so construction and every mutation path (adding a child) are
  serialized to that thread.
- **Error states**: Not applicable — the component has no dependency on
  network, database, or file-system access, and the source shows no error
  path of any kind.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking.
- **No removal API**: Adding a view is the only mutation entry point the
  source exposes; there is no corresponding operation for removing an
  arranged child. Once a view is added, the source itself provides no
  supported way to remove it again through this wrapper — a caller cannot
  reach the internal stack view's arranged children directly, since it is
  not exposed, and would instead have to remove the child view from its
  parent directly.

