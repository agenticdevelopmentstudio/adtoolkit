
- **Null/empty input**: the manifest bytes as an empty input MUST be
  returned unchanged — an empty input cannot be parsed as JSON/JSONC, and
  that failure resolves to "leave unchanged" the same way any other
  unparseable input does. A `package.nls.json` whose content is the valid,
  empty object `{}` MUST leave the merged table empty and MUST NOT change
  the localization function's no-table behavior.
- **Boundary values**: A string of exactly two percent signs (`"%%"`) MUST
  NOT be treated as a placeholder — it is too short. A string of exactly
  three characters (`"%x%"`, the shortest possible placeholder) MUST be
  treated as one. A key containing any `%` character, at any position,
  MUST be rejected before lookup.
- **Concurrent access**: This component holds no stored state; every
  function is a pure function of its arguments and touches only local
  values and freshly-read files, never a shared cache. Both of the
  manifest's readers call the localization function from contexts with no
  isolation requirement of their own, and concurrent, independent calls
  with independent directory arguments MUST NOT require external
  synchronization. Two concurrent calls that both name the same directory
  while one of its table files is being modified on disk are not
  independent, and the file system's own read consistency, not this
  component, decides what either call sees.
- **Error states**: A directory that does not exist, cannot be listed, or
  holds a `package.nls*.json` file that cannot be read or does not parse as
  JSON/JSONC MUST NOT fail the localization function; every such failure
  resolves to that file (or the whole table) contributing no entries, per
  **unreadable-directory-yields-no-tables**,
  **unreadable-table-file-contributes-nothing**, and
  **malformed-table-contributes-nothing**. None of these failures is
  surfaced anywhere — not as a thrown error, a return value, or a log line
  (see Logging) — which is a deliberate design choice, not an omission (see
  Design Decisions).
- **Offline/disconnected state**: Not applicable — this component performs
  no network access of any kind; every step operates only on local
  file-system reads against the directory it is given.
- **Cancellation and timeouts**: Not applicable — the localization
  function is a synchronous operation with no cooperative cancellation
  check and no timeout of any kind anywhere in this component; it always
  runs to completion once called.

