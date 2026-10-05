
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `opts.deploySyncIntervalMs` | `number` | none — required on every call | The recurring interval, in milliseconds, between allowed full syncs once the boot grace has passed. This file never reads an environment variable itself; the shipped caller (`config/port.ts`'s `deploySyncIntervalMs()` function, a different, external construct despite the identical name) derives this value from the `DEPLOY_SYNC_SECONDS` environment variable or a `max(300_000, 5 × probe interval)` default. |
| `opts.firstDelayMs` | `number \| undefined` | `FIRST_FULL_SYNC_DELAY_MS` (60,000) | Delay, in milliseconds, before the first automatic full sync after the `DeployCadence` is constructed (i.e. after process boot, for the shipped call site). |
| `opts.now` | `(() => number) \| undefined` | `Date.now` | Injectable clock, used by `cadence.test.ts` to drive time deterministically without real timers; production call sites never override it. |
| `FIRST_FULL_SYNC_DELAY_MS` (module constant) | `number` | `60_000` | Exported so callers and tests can reference the default first-delay value by name instead of repeating the literal. |

