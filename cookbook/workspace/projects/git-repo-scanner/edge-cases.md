
- **Null and empty input**: An empty `roots` list MUST cause a scan to
  return an empty array immediately, since there is nothing to iterate. An
  empty `rootSkipPatterns` list MUST skip nothing by name at any depth, per
  `root-level-skip-patterns`.
- **Boundary values**: `rootSkipPatterns` is applied only when `depth == 1`
  exactly; at depth `0` (a scan root itself) and at any depth `2` or
  greater it is never consulted, per `root-level-skip-patterns`. MUST.
- **Concurrent access**: The scanner is safely usable across concurrent
  contexts and a scan keeps every piece of mutable traversal state local to
  the call (the results found so far, the visited set, the traversal
  stack); the only state shared across concurrent calls on one instance is
  the fixed `roots` and `rootSkipPatterns`, so multiple concurrent scans on
  the same instance MAY run with no synchronization and no shared-state
  hazard. MUST.
- **Error states**: Reading a directory's contents failing for any reason —
  permission denied, the directory disappearing mid-walk — is caught and
  skipped identically, with no distinction made between error causes and
  no signal returned to the caller; see the pending decision on
  `unreadable-directory-error-visibility`. A malformed or non-UTF-8
  `.git/config` is handled the same way as a config with no origin
  section: reading the origin remote returns no value in both cases, with
  no way for a caller to distinguish "corrupt" from "absent". MUST.
- **Offline or disconnected state**: Not applicable — this component makes
  no network call of any kind; its only I/O is local filesystem access and
  local file reads.
- **Missing file or unreachable root**: A root location that does not
  exist on disk is not special-cased; reading its contents fails exactly
  as it would for a permission-denied directory, and that root is silently
  skipped with the walk continuing to any remaining roots — see the open
  question on `unreadable-directory-error-visibility`. MUST.
- **Malformed config line endings**: Reading the origin remote splits
  `.git/config` text on newlines and trims each line of ordinary
  whitespace, which strips spaces and tabs but not a trailing carriage
  return; a `config` file using CRLF line endings MUST retain a trailing
  carriage return on the section-header comparison string and on any
  parsed `url` value, since ordinary whitespace trimming does not include
  it. This can cause the `[remote"origin"]` comparison to fail to match, or
  the returned remote string to carry a trailing carriage return, on a
  CRLF-encoded config. MUST (describes the actual, deterministic behavior;
  not a marker, since the source never declares an intent to normalize
  line endings).
- **Cancellation**: The cancellation check is consulted once per directory
  popped from the stack, before that directory's children are read; a
  cancellation observed partway through a multi-root scan MUST return only
  the repositories found before cancellation was observed, sorted. MUST.
- **Symlink cycles**: Because the descend decision excludes every symbolic
  link before it is ever pushed onto the stack, a symlink that would
  otherwise create a cycle (e.g. pointing at an ancestor directory) MUST
  NOT be traversed and therefore MUST NOT cause an infinite loop.

