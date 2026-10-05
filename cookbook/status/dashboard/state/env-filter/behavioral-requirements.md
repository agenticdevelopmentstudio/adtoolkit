
### Public operation

- **signature**: Environment Filter MUST take no arguments and MUST return an object with exactly three fields: `envs` (a set of selected environment names), `all` (an ordered list of every environment), and `toggle` (a function taking one environment name and returning nothing).
- **all-list**: The `all` field MUST be the `ENVIRONMENTS` constant, in its declared order `production`, `staging`, `testing`, and MUST be the same list instance on every read.
- **toggle-identity**: The `toggle` function MUST keep the same identity across the life of one instance, so consumers MAY depend on that stability without causing needless re-runs.
- **envs-immutability**: Each state change MUST produce a new set instance; the previous set MUST NOT be mutated, so consumers comparing `envs` by reference observe every change.

### Initial state and hydration

- **default-all-selected**: Before hydration, Environment Filter MUST return `envs` containing every entry of `ENVIRONMENTS`, regardless of what storage holds.
- **deferred-hydration**: Environment Filter MUST read storage only after the initial state is established, exactly once per instance, so a pre-hydration render and the first paint both show the default.
- **storage-key**: Environment Filter MUST read and write the storage key `"adh-env-filter"`.
- **absent-value-keeps-default**: When the stored value is missing (a read that returns nothing) or is the empty string, hydration MUST leave `envs` at the default.
- **array-hydration**: When the stored value parses as a JSON array, hydration MUST replace `envs` with a set of the array's elements that are strings and members of `ENVIRONMENTS`, in the array's order.
- **invalid-entries-dropped**: Hydration MUST silently drop array elements that are not strings or not members of `ENVIRONMENTS`.
- **filtered-to-empty**: When filtering leaves no valid elements (including a stored empty array `[]`), hydration MUST set `envs` to an empty set (nothing selected), not fall back to the default.
- **duplicates-collapse**: Duplicate names in the stored array MUST collapse to one member, because the result is a set.
- **non-array-keeps-default**: When the stored value parses as valid JSON that is not an array (an object, number, string, boolean or null), hydration MUST leave `envs` at the default.
- **read-failure-keeps-default**: When the storage read throws or the stored value is not valid JSON, hydration MUST catch the exception, leave `envs` at the default, and MUST NOT propagate the error or log it.

### Toggle

- **toggle-flip**: `toggle(env)` MUST remove `env` from the selection when it is present and add it when it is absent.
- **toggle-order**: A name added by `toggle` MUST be appended after the existing members in the set's iteration order.
- **toggle-unvalidated**: `toggle` MUST NOT validate `env` against `ENVIRONMENTS`; an unknown name is added to the in-memory set and persisted like any other. Only hydration filters to `ENVIRONMENTS`, so an unknown name is dropped on the next hydration. Callers pass names taken from `all`, which is the precondition the Overview meets.
- **toggle-may-empty**: `toggle` MUST allow the selection to become empty; there is no minimum of one selected environment.
- **toggle-functional-update**: `toggle` MUST derive the next selection from the latest state, so several toggles made together compose rather than overwrite each other.
- **toggle-persist**: After computing the next selection, `toggle` MUST write it to `"adh-env-filter"` as a JSON array of the set's members in iteration order (for example `["production","testing"]`).
- **write-failure-ignored**: When the storage write throws (storage unavailable, quota exceeded), `toggle` MUST catch the exception, MUST still apply the new in-memory selection, and MUST NOT propagate or log the error.

### Ordering, concurrency and scope

- **single-threaded**: All reads, writes and state updates run on a single execution thread; hydration and toggles cannot interleave, and hydration completes before a later user event is handled.
- **write-inside-updater**: The storage write happens inside the state-update step itself. That step MAY run more than once for the same logical update; a repeat write stores the same value, so the effect is idempotent.
- **per-instance-state**: Each instance MUST hold its own selection; a toggle in one instance MUST NOT update another active instance until that instance is recreated and re-hydrates.
- **no-cross-tab-sync**: Environment Filter MUST NOT listen for cross-tab storage-change notifications; a change made in another tab is not reflected until this instance is recreated.
- **no-other-side-effects**: Environment Filter MUST NOT perform network requests, logging, timers or any storage access other than one read per instance and one write per toggle.
- **client-only**: Environment Filter MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

