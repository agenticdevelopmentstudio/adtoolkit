
### Public operation

- **signature**: Source Filter MUST take no arguments and MUST return an object with exactly two fields: `sources` (the set of selected sources) and a toggle operation that takes one source and returns nothing.
- **source-type**: The toggle operation's parameter MUST be one of the seven fixed source values. The type signature is the caller precondition. Source Filter does no runtime membership check.
- **toggle-identity-unstable**: The toggle operation MUST be a new function value each time Source Filter is used, because the source does not give it a stable identity. A consumer that lists it in a dependency list re-runs every time.
- **sources-immutability**: Each toggle MUST produce a new set instance and MUST NOT mutate the previous one, so a consumer that compares `sources` by reference sees every change.

### Initial state

- **default-all-selected**: On the first use of each mount, `sources` MUST contain every one of the seven fixed sources, in their defined order.
- **lazy-seed**: The initial set MUST be built once per use, computed lazily rather than on every render. Later renders MUST NOT rebuild it.
- **seed-decoupled**: The seeded set MUST be a copy. Mutating it MUST NOT alter the fixed source list, and the reverse also holds.

### Toggle

- **toggle-flip**: The toggle operation MUST remove a source from the selection when it is present and add it when it is absent.
- **toggle-order**: A source added by the toggle operation MUST come after the existing members in the set's iteration order.
- **toggle-may-empty**: The toggle operation MUST allow the selection to become empty. There is no minimum of one selected source.
- **toggle-functional-update**: The toggle operation MUST derive the next selection from the latest state, so several toggles in one batch of updates compose instead of overwriting each other.
- **toggle-no-error**: The toggle operation MUST NOT throw and MUST NOT return a value. No operation in Source Filter can fail.

### Ordering, concurrency and scope

- **single-threaded**: All state updates run on a single execution thread, so toggles cannot interleave. Updates apply in the order they are issued.
- **updater-pure**: The state update MUST have no side effects. The environment MAY apply it more than once for the same input, and each application returns an equivalent set built from the same starting state.
- **per-instance-state**: Each use MUST hold its own selection. A toggle in one use MUST NOT change another concurrent use.
- **no-persistence**: The selection MUST NOT be written to or read from any storage. It resets to all-selected on every remount and every reload.
- **no-side-effects**: Source Filter MUST NOT make network requests, log, start timers, or subscribe to anything.
- **client-only**: Source Filter MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

