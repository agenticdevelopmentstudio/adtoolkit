
### Constant and Type Shape

- **first-full-sync-delay-constant**: The module MUST export `FIRST_FULL_SYNC_DELAY_MS` with the value `60_000` (60,000 milliseconds).
- **deploy-cadence-interface-shape**: The `DeployCadence` interface MUST declare exactly one member, `shouldFullSync(manual: boolean): boolean`, and MUST declare no other property or method.

### Construction (`createDeployCadence`)

- **required-deploy-sync-interval**: `createDeployCadence` MUST require its caller to supply `opts.deploySyncIntervalMs` as a number; the factory declares no default for this field.
- **first-delay-default**: `createDeployCadence` MUST use `opts.firstDelayMs` when it is a non-`null`, non-`undefined` value, and MUST otherwise use `FIRST_FULL_SYNC_DELAY_MS` (60,000) as the delay before the first full sync.
- **clock-default**: `createDeployCadence` MUST use `opts.now` when it is a non-`null`, non-`undefined` value, and MUST otherwise use `Date.now` as the clock; every timing decision inside the returned `DeployCadence` MUST read the current time by calling this resolved clock function, never `Date.now` directly.
- **initial-anchor-set-at-creation**: `createDeployCadence` MUST compute the first pending full-sync anchor once, at the moment it is called, as the resolved clock's current reading plus the resolved `firstDelayMs`; this computation MUST happen before the returned `DeployCadence`'s `shouldFullSync` is ever invoked, not lazily on first use.

### Cadence Decision (`shouldFullSync`)

- **manual-forces-full-sync**: `shouldFullSync` MUST return `true` whenever its `manual` argument is `true`, regardless of the pending anchor or how much time has elapsed since construction or the last full sync.
- **boot-grace-blocks-automatic-sync**: `shouldFullSync` MUST return `false` when `manual` is `false` and the clock's current reading is earlier than the pending anchor.
- **automatic-sync-after-anchor-elapsed**: `shouldFullSync` MUST return `true` when `manual` is `false` and the clock's current reading is no longer earlier than the pending anchor (i.e. the anchor time has been reached or passed).
- **reanchor-on-true-result**: Every call to `shouldFullSync` that returns `true` — whether forced by `manual` or triggered by the elapsed anchor — MUST set the pending anchor to that call's own clock reading plus `opts.deploySyncIntervalMs`, replacing whatever anchor was pending before the call.
- **anchor-unchanged-on-false-result**: A call to `shouldFullSync` that returns `false` MUST NOT modify the pending anchor in any way; the next call MUST see exactly the anchor that was pending before the `false`-returning call.

### Instance Independence

- **independent-per-call-state**: Each call to `createDeployCadence` MUST produce a `DeployCadence` with its own private, independently mutable anchor, closed over by the returned object; `createDeployCadence` MUST NOT share the anchor between two `DeployCadence` values it produces, and MUST NOT expose any way to read or set the anchor other than through `shouldFullSync`'s return value.

### Input Validation

- **interval-and-delay-validation**: a positive, finite `deploySyncIntervalMs` and a non-negative `firstDelayMs` are caller preconditions; `createDeployCadence` does not check them. A `deploySyncIntervalMs` of `0`, a negative value, or `NaN` makes `reanchor-on-true-result` land the anchor at or before the current clock reading, so `shouldFullSync(false)` returns `true` on every tick; a negative `firstDelayMs` makes the first automatic call after construction return `true`, running the heavy phase on the boot tick. The production caller satisfies the precondition through `config/port.ts`'s `deploySyncIntervalMs()`, which floors its output at 300,000ms via `Math.max`.

