
- **Null and empty input**: setting the skip-patterns setting's value to
  an explicit empty list leaves a later read of its value returning an
  empty list; removing it instead leaves a later read returning the
  non-empty default skip-pattern list, because
  **removal-reverts-to-default** reverts to whatever the default value is,
  not to an empty list. The empty string is also accepted as an ordinary
  member of the list, with no special-case rejection
  (**no-pattern-validation**). MUST behave this way.
- **Boundary values**: no maximum is imposed on the number of entries in
  the skip-patterns setting or on the length of any one entry; a list with
  hundreds of patterns is JSON-encoded and stored as one binary blob the
  same way a single-entry list is (**array-setting-json-encoded**). MUST
  behave this way.
- **Concurrent access**: every read, write, and remove on all three
  settings is confined to the main execution context
  (**main-thread-confinement**), so two calls issued from different
  concurrent tasks MUST execute in some serialized order with no
  interleaving of the underlying storage access — that confinement, not
  this file, is what rules out a data race. MUST behave this way.
- **Error states**: an encoding failure during a write to the
  skip-patterns setting is swallowed — the storage provider attempts the
  encode and simply returns, sending no change notification, if it fails.
  Encoding an ordinary list of strings does not fail in practice, so this
  path is unreachable for this specific setting; it is documented here
  because it is a real, inherited behavior of the storage layer this
  setting depends on, not because it is expected to occur. SHOULD be
  understood as inherited, unreachable-for-this-type behavior, not a gap
  in this declaration.
- **Offline or disconnected state**: not applicable — this declaration
  performs no network call of any kind; the backing store is local,
  on-device storage with no connectivity dependency.

