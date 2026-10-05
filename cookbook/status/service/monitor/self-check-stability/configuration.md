
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `checks` (parameter of `stabilize`) | `IntegrationCheck[]` | none — required on every call | The current run's per-provider results; each entry's `id` is treated as its own independent debounce identity across calls. |
| `nowMs` (parameter of `stabilize`) | `number \| undefined` | `Date.now()` | The current time used for streak arithmetic and the `CONFIRM_WINDOW_MS` comparison; the sole production caller (`integrations.ts`'s `runIntegrationsCheck`) forwards its own `nowMs` argument here unchanged. |
| `CONFIRM_RUNS` (module constant) | `number` | `2` | Not configurable at runtime — a compile-time constant; changing the debounce run count requires editing the source. |
| `CONFIRM_WINDOW_MS` (module constant) | `number` | `90_000` | Same as above, for the wall-clock span. |
| `CORRELATED_MIN` (module constant) | `number` | `2` | Same as above, for the correlation threshold. |

`createSelfCheckStabilizer()` itself takes no configuration of any kind — its entire tunable surface is the three module constants above plus the two `stabilize` parameters.

