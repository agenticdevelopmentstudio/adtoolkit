
### Signature and return value

- **signature**: Refresh All MUST take one optional numeric input (the refresh interval in milliseconds) and MUST return an object with a `refreshAll` function that takes no arguments and returns nothing.
- **interval-default**: When called with no argument, the interval MUST default to `60,000` (60 seconds).
- **return-shape**: Refresh All MUST return an object with exactly one member, `refreshAll`, a zero-argument function returning nothing.
- **refresh-all-stable**: The `refreshAll` function MUST keep a stable identity for as long as the shared cache context stays the same.
- **return-object-fresh**: Refresh All MUST return a new wrapper object each time it is used. Only `refreshAll` inside it keeps a stable identity.

### Refresh selection

- **refetch-call**: Each invocation of `refreshAll` MUST trigger a refetch of matching cache entries exactly once, using a filter and no other option.
- **live-excluded**: The filter MUST reject every cache entry whose key's first element is exactly the string `"live"`. This includes keys with more elements, such as `["live", "x"]`.
- **live-prefix-only**: The live exclusion MUST compare only the first key element. A key such as `["live-history"]` or `["history", "live"]` MUST NOT be excluded.
- **disabled-excluded**: The filter MUST reject every cache entry that has no enabled observer.
- **others-included**: The filter MUST accept every other cache entry, whatever its key.
- **no-key-list**: Refresh All MUST NOT hold a list of the datasets it refreshes. Which entries get refetched depends only on what is in the shared cache at the moment of the call.
- **disabled-means-no-enabled-observer**: The disabled test MUST be false while any observer of that cache entry is enabled, so one enabled observer on a key makes that entry refreshable even if other observers on the same key are individually disabled.
- **inactive-queries-eligible**: Refresh All MUST NOT restrict refetching to entries that are currently observed. It applies no extra filter of its own, so it uses the shared cache's own default, which includes cached entries with no active observer that have fetched before and are still inside their retention window. That behavior belongs to the shared cache, not to Refresh All.

### Fire-and-forget and errors

- **fire-and-forget**: `refreshAll` MUST discard the result of triggering the refetch. It MUST return synchronously, before any refetch settles.
- **no-await-no-signal**: `refreshAll` MUST NOT tell its caller whether a refetch succeeded or failed.
- **errors-land-on-queries**: A refetch failure MUST show up only in the failing entry's own cache state (its error and status), where that entry's observers read it. Refresh All applies no error-throwing option, so the aggregate refresh operation resolves even when an individual entry fails. No unhandled failure reaches the page.
- **independent-completion**: The refetches MUST start in the same refresh operation, but each one settles on its own schedule. Refresh All MUST NOT hold back results until all refetches finish, and it MUST NOT roll back an entry whose refetch succeeded when another entry's refetch fails.
- **in-flight-restart**: Refresh All MUST NOT override the shared cache's default in-flight-restart behavior. Under that default, an entry that is already fetching when a tick fires has that fetch cancelled and restarted. That behavior belongs to the shared cache, not to Refresh All.

### Interval lifecycle

- **interval-start**: Once started, Refresh All MUST schedule `refreshAll` on a repeating timer every `intervalMs` milliseconds.
- **no-immediate-refresh**: Refresh All MUST NOT call `refreshAll` immediately when it starts. The first automatic refresh MUST happen `intervalMs` after it starts running.
- **interval-cleanup**: When the caller stops using it, Refresh All MUST cancel its timer, and no further automatic refresh MUST fire from that use.
- **interval-restart-on-change**: When the interval or the shared cache context changes, Refresh All MUST cancel the old timer and start a new one with the new values, which resets the tick phase.
- **one-timer-per-mount**: Each use MUST own exactly one timer. Two uses sharing the same cache context run two independent timers, and Refresh All does nothing to coordinate or deduplicate them.
- **no-visibility-pause**: Refresh All MUST NOT pause its timer when the app is in the background or offline. Any throttling of a backgrounded timer comes from the environment's own policy, not from Refresh All.
- **no-input-validation**: Refresh All MUST pass the interval to the timer unchanged, with no range check.

### Concurrency and side effects

- **single-threaded**: Refresh All runs on a single execution thread. `refreshAll` calls and timer ticks cannot interleave. Each call finishes selecting and starting its refetches before the next begins.
- **side-effects**: Refresh All's only side effects MUST be its one timer and the refetches it asks the shared cache to start. It MUST NOT write storage, log, emit analytics or perform network I/O directly. Every network request comes from the refetched entries' own read functions.
- **client-only**: Refresh All MUST run only in a live client execution context; it has no server-only or universal-rendering variant.
- **cache-context-required**: Refresh All MUST be used only where a shared cache context is available. Accessing the cache context fails when none is available.

