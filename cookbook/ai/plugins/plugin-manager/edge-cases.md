
- Empty search paths (no locations to scan): discovery MUST leave the discovered descriptors and available templates empty; no error is raised.
- A search-path entry that does not exist on disk: MUST be skipped silently by `existing-search-paths-only`; no log, no error.
- A search-path entry that exists but cannot be enumerated (permissions failure, or a non-directory file at that path): silently skipped with no log — see `search-path-enumeration-failure` and its Design Decision.
- A directory entry with the plugin extension that is not a valid bundle: caught by `unreadable-candidate-skip` (the bundle cannot be opened), logged and skipped, MUST NOT throw.
- The descriptor file absent, unreadable, or not valid JSON for the declared descriptor shape: caught by `unreadable-candidate-skip`, logged and skipped, MUST NOT throw. This is also how a pre-descriptor plugin (no descriptor file at all) is ignored, per the source's own documentation.
- The schema version below the minimum or above the current maximum: caught by `schema-version-filter`, logged and skipped, MUST NOT throw.
- The same identifier discovered from two or more search paths (including the same identifier appearing twice in one directory listing, which cannot occur since file names are unique): only the first-recorded one is kept, per `duplicate-identifier-first-wins`.
- Loading a plugin for an identifier never discovered: MUST fail with a not-found error, per `load-unknown-identifier`.
- Loading a plugin called concurrently is not a distinct case: the manager's single-context confinement (`single-context-confinement`) means two calls are always serialized, never truly concurrent; there is no data race to define behavior for.
- Unloading a plugin for an identifier that was never loaded: removing a non-existent cache entry is a no-op, but the info log fires anyway, per `unload-always-logs`.
- Cancellation: none of the manager's operations are asynchronous or accept a cancellation token; there is nothing to cancel. Not applicable.
- Timeouts: discovery and loading a plugin perform only synchronous local file-system and code-loading calls, with no network access and no timeout parameter. Not applicable.
- Test registration exists only in builds with testing support enabled; in a release/production build the operation does not exist at all, per `testing-registration-debug-only`.
- Offline/disconnected state: the manager makes no network requests of its own (that is the loaded plugin's and its transport's job); connectivity loss cannot affect discovery or loading. Not applicable.

