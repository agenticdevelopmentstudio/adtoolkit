
- **Null/empty input**: Not applicable — the add-arranged-view
  operation's parameter is a non-optional view; the type system rejects a
  missing argument at compile time. The parameterless constructor and the
  frame-accepting constructor (whose argument is discarded, see Design
  Decisions) leave no other caller-supplied value that could be null or
  empty. Calling the add-arranged-view operation zero times is a valid,
  un-special-cased path: the internal stack's arranged children stay
  empty and the component collapses to whatever natural size an empty
  internal stack resolves to.
- **Boundary values**: The standard group-spacing value is read exactly
  once, into the internal stack's spacing, at construction time (see
  **sets-arranged-subview-spacing-from-group-spacing-token**). The shared
  layout-metrics source is a live, observable value, but the component
  never subscribes to it, so if a caller mutates that underlying value
  after a component instance already exists, that instance's spacing does
  not update — it stays at whatever the group-spacing value was when it
  was constructed. This is the same staleness pattern documented for the
  sibling divider and horizontal-stack-view wrappers.
- **Concurrent access**: Not applicable — the component is confined to
  the UI thread (see **confines-to-ui-thread**), so construction and every
  mutation path (the add-arranged-view operation, or direct manipulation
  of the exposed internal stack view) are serialized to that thread.
- **Error states**: Not applicable — the component has no dependency on
  network, database, or file-system access, and shows no error path of
  any kind.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking.
- **No dedicated removal operation, but the internal stack view is
  directly reachable**: The add-arranged-view operation is the only
  mutation method the component exposes; there is no remove-arranged-view
  or equivalent operation on the component itself. Because the internal
  stack view is public (see Design Decisions), a caller CAN reach it
  directly and remove an arranged child, reorder its arranged children, or
  change its alignment/distribution without going through this wrapper's
  API.

