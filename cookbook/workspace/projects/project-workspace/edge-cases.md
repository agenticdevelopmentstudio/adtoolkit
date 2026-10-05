
- **Null and empty input**: Reading stored tabs treats a load result
  whose tabs list is empty the same as a thrown error — both produce
  nothing (**stored-tabs-nil-when-empty-or-absent**, MUST). Reading a
  pane-state list for an unset key, or for a key holding a string that
  is not valid text or not valid JSON, returns an empty list rather than
  throwing or crashing (**pane-state-list-json-encoded**, MUST). Writing
  a pane-state list with an empty values list clears the key instead of
  writing an empty-list literal (**pane-state-list-json-encoded**,
  MUST).
- **Boundary values**: Allocating a pane number's counter starts at `1`
  and has no declared upper bound; it is a plain integer, so the
  boundary this file defines no behavior for is integer overflow, which
  the language traps on rather than wrapping (MUST, by the language's
  own arithmetic semantics — not a case this file guards against
  itself). Computing the initial tabs' stored-tab path is only reached
  when the stored tabs list is non-empty, because reading stored tabs
  already filters the empty case out, so the first-tab fallback in
  **active-tab-fallback** never indexes an empty list.
- **Concurrent access**: Every property and method here is confined to
  the main execution context (**confines-to-ui-thread**), so no two
  calls on one workspace instance can interleave their mutations of the
  repository, the pane-number counter, or either weak cache. Two
  separate workspace instances built over the same repository id (a
  project opened in two windows) can still race at the database layer —
  persisting tabs, writing a setting, writing pane state, and persisting
  project directories from one instance are not serialized against
  calls from another — but ordering that race, when it matters, is the
  project controller's job (see
  `adtoolkit://cookbook/workspace/projects/project-controller`),
  not this file's; the workspace itself makes no ordering claim across
  instances.
- **Error states**: Every database-backed operation except reading
  stored tabs catches its error, logs it, and returns a safe default —
  nothing, an empty list, or nothing at all — rather than propagating it
  (**persist-tabs-swallows-failure**,
  **pane-state-failures-swallowed-and-logged-with-full-context**,
  **project-setting-scoped-by-repo**,
  **project-directories-load-failure-yields-empty**, all MUST). The one
  exception, reading stored tabs' unlogged failure path, has no log
  signal at all — see **stored-tabs-load-failure-signal**.
- **Offline or disconnected state**: Not applicable in the network sense
  — every dependency this file reads or writes (the database, the
  filesystem paths it resolves symlinks against) is local. The
  git-status-provider lookup hands out an object built on the project's
  git client, but the git subprocess calls that object goes on to make
  are that object's own concern, not this file's (see
  `adtoolkit://cookbook/foundation/git/git-client`).
- **Cancellation and timeouts**: No operation on the workspace is
  asynchronous; every operation here is a synchronous database call, a
  synchronous cache lookup, or a pure computation, so there is no
  cancellation token, timeout, or unit of concurrent work for this file
  to honor or ignore (MUST, by the absence of any asynchronous signature
  in the source).
- **Missing file or unreachable server**: A primary/directory argument
  that does not exist on disk is not distinguished from one that does —
  resolving symlinks on a nonexistent path returns the path unchanged,
  so the file-browser-directories lookup and the git-status-provider
  lookup still mint and cache an object keyed to it
  (**file-browser-directories-cached-per-resolved-primary**,
  **git-status-provider-cached-per-resolved-directory**, MUST, by the
  absence of any existence check in either method).

