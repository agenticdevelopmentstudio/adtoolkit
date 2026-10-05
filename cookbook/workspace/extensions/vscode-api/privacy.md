
- **Data collected**: none of its own; the bridge holds no stored state and collects nothing about the user. It transiently handles values an extension itself supplies (its callbacks, its thenables, its error objects) for the duration of one call.
- **Storage**: none — the bridge is a stateless collection of operations with no persisted or cached data of its own; the trampoline objects it caches on the global scope live only for the lifetime of their script context.
- **Transmission**: none — everything happens in-process inside the script engine; nothing here makes a network call or writes to disk.
- **Retention**: an extension-supplied value is retained only as long as the call stack that produced it, or (for reading a settlement) until the thenable it is watching settles or its script context is torn down; installing a member's weak capture of its owner ensures a torn-down adaptor is not kept alive by a still-reachable script callback.

