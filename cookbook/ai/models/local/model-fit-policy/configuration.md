
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `warnPct` (parameter to the tier, fit-info, picker-label computations) | integer | the default warn threshold (25) | Percentage of RAM at or above which the estimated footprint is `warn`. |
| `blockPct` (parameter to the tier, fit-info, picker-label computations) | integer | the default block threshold (50) | Percentage of RAM at or above which the estimated footprint is `block`. |
| `warnPct`, `blockPct` (parameters to the verdict computation) | integer, integer | none — required | Same meaning as above, but the verdict computation has no default; the caller MUST supply both explicitly. |
| `diskBytes` (parameter to the tier, verdict, fit-info, picker-label computations) | optional integer | none — required | On-disk size in bytes of the candidate model; absent means unknown. |
| `physicalRAM` (parameter to the tier, verdict, fit-info, picker-label computations) | unsigned integer | none — required | The machine's physical RAM in bytes. |
| `pressure` (parameter to the verdict and pressure-verdict computations) | memory pressure level | none — required | Latched OS memory-pressure snapshot (`normal`/`warning`/`critical`). |
| `model` (parameter to the verdict and picker-label computations) | string | none — required | Model name/tag, included verbatim in the returned text. |

This policy defines no environment variable. It declares two settings-key
constants, the warn-threshold key (`ai_guard_warn_pct`) and the
block-threshold key (`ai_guard_block_pct`), but reads neither itself —
resolving them through a host's settings store is the caller's
responsibility, as documented in the sibling inference-guard recipe (the
open question of *where* those keys are persisted is that recipe's concern,
not this one's).

