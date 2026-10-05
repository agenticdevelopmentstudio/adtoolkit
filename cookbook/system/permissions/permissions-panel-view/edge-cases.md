
- **Null/empty input** (MUST): the permissions list MUST be permitted to
  be empty. The component MUST then build zero rows, and refreshing MUST
  complete immediately with no row refreshed — both the row-construction
  step and the refresh operation iterate the given collection with no
  special-casing for zero elements.
- **Duplicate values** (MUST): a permissions list containing the same
  permission value more than once (for example two Accessibility entries)
  MUST still produce one row per entry, including the duplicate; the
  component performs no deduplication when building rows.
- **Concurrent access** (MUST): every property and operation of the
  component is confined to a single execution context, so its internal
  state is serialized. Window attach, app activation, and a completed
  grant action can all ask for a refresh in close succession; the
  component MUST resolve that through the cancel-and-replace pattern named
  in **latest-refresh-wins**, cancelling whatever refresh is already in
  flight before starting the new one.
- **Error states** (MUST): the status-checking and request operations are
  non-throwing, so the component has no failure path and performs no
  error handling of its own. The status value has no "error" case, so a
  misbehaving checker implementation can only surface as granted, denied,
  or undetermined — this component does not detect or separately report a
  failing checker.
- **Offline/disconnected state**: Not applicable. The component makes no
  network call directly; any network or cross-process dependency a
  particular permission's status check has is the injected checker's
  concern, not this component's.

