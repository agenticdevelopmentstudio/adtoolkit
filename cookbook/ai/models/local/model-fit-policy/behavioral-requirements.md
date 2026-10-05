
- **memory-pressure-cases**: The memory pressure level type MUST expose
  exactly three cases — `normal`, `warning`, and `critical` — each
  comparable for equality and safe to pass across concurrent boundaries,
  with a stable string form for each case.
- **tier-cases**: The tier type MUST expose exactly three cases — `ok`,
  `warn`, and `block` — each comparable for equality and safe to pass
  across concurrent boundaries.
- **verdict-cases**: The verdict type MUST expose exactly three cases —
  `allow`, `block` (carrying a reason), and `deferred` (carrying a reason)
  — each comparable for equality and safe to pass across concurrent
  boundaries, with each refusal case carrying a human-readable reason
  string.
- **fit-info-shape**: The fit-info structure MUST be comparable for
  equality and safe to pass across concurrent boundaries, exposing
  immutable `text` and `tier` fields, constructible only through its
  public initializer.
- **namespace-isolation**: This policy MUST be exposed as an uninstantiable
  namespace holding no stored state of its own, whose public members are
  exclusively constants and pure functions; because it declares no
  concurrency isolation of its own, every member MUST be callable
  synchronously from any concurrency context without waiting on it.
- **resident-overhead-multiplier**: The resident overhead multiplier MUST
  equal `1.2`.
- **estimated-bytes**: The estimated-bytes computation MUST return the
  on-disk byte count multiplied by the resident overhead multiplier,
  truncated to a whole number of bytes.
- **default-thresholds**: The default warn threshold MUST equal `25` and
  the default block threshold MUST equal `50` (both percentages of RAM).
- **threshold-setting-keys**: The warn-threshold setting key MUST equal the
  literal string `ai_guard_warn_pct` and the block-threshold setting key
  MUST equal the literal string `ai_guard_block_pct`.
- **tier-unknown-size**: The tier computation MUST return nothing when the
  disk size is unknown.
- **tier-zero-ram**: The tier computation MUST return nothing when
  physical RAM is `0`.
- **tier-classification**: When the disk size is known and physical RAM is
  greater than `0`, the tier computation MUST compute a percentage as the
  estimated resident bytes divided by physical RAM, times `100`, and MUST
  classify it as `block` when the percentage is at or above the block
  threshold, `warn` when it is at or above the warn threshold and below
  the block threshold, and `ok` when it is below the warn threshold.
- **tier-threshold-defaults**: The tier, fit-info, and picker-label
  computations MUST each default an omitted warn threshold to the default
  warn threshold and an omitted block threshold to the default block
  threshold.
- **pressure-verdict-normal**: The pressure verdict MUST be `allow` when
  pressure is `normal`.
- **pressure-verdict-elevated**: The pressure verdict MUST be `deferred`,
  with a reason string of exactly the form
  `memory pressure is <pressure>; deferring local inference`, when
  pressure is `warning` or `critical`.
- **verdict-pressure-precedence**: The verdict computation MUST evaluate
  the pressure verdict first and, whenever that result is `deferred`, MUST
  return that exact deferred result without evaluating the size tier at
  all — regardless of disk size, model, or the thresholds.
- **verdict-required-thresholds**: The verdict computation's warn and block
  threshold inputs MUST carry no default value; the caller MUST supply
  both explicitly — unlike the tier, fit-info, and picker-label
  computations.
- **verdict-allow-non-block-tier**: Under `normal` pressure, the verdict
  computation MUST return `allow` whenever the computed tier is `ok`,
  `warn`, or unknown (unknown size) — only a `block` tier with a known
  disk size yields a refusal.
- **verdict-block-reason-format**: When the computed tier is `block` and
  the disk size is known, the verdict computation MUST return a `block`
  result with a reason string of exactly the form
  `<model> needs <footprint description> est.; block threshold is <block threshold>% of <RAM as a GB string>`,
  where the embedded footprint description is computed from the estimated
  (not on-disk) resident bytes.
- **footprint-description-format**: The footprint-description computation
  MUST return a string of exactly the form
  `~<estimated bytes as a GB string> (~<estimated bytes as a percentage of RAM>% of RAM)`.
- **fit-info-unknown**: The fit-info computation MUST return nothing when
  the disk size is unknown or when the tier computation returns nothing.
- **fit-info-ok-text**: For an `ok` tier, the fit-info computation MUST
  return text of exactly the form
  `<disk size as a GB string> (~<percentage of RAM>% of RAM)` paired with
  tier `ok`, displaying the on-disk size rather than the estimated
  resident size.
- **fit-info-warn-text**: For a `warn` tier, the fit-info computation MUST
  return text of exactly the form
  `<disk size as a GB string> ⚠ large: ~<percentage of RAM>% of RAM`
  paired with tier `warn`.
- **fit-info-block-text**: For a `block` tier, the fit-info computation
  MUST return text of exactly the form
  `<disk size as a GB string> — won't run: exceeds memory budget` paired
  with tier `block`; unlike the `ok`/`warn` text, the block text MUST NOT
  include a RAM-percentage figure.
- **picker-label-unknown**: The picker-label computation MUST return the
  model name unchanged when the fit-info computation returns nothing.
- **picker-label-known**: The picker-label computation MUST return the
  exact string `<model> — <fit-info text>` when the fit-info computation
  returns a value.
- **gb-string-format**: Formatting a byte count as a GB string MUST render
  the value, divided by `1,000,000,000`, to exactly one decimal place
  followed by ` GB`, using a fixed, locale-independent numeric format
  regardless of the caller's own locale.
- **ram-pct-computation**: Computing a byte count's percentage of RAM MUST
  return the nearest whole percentage, rounded half-away-from-zero, when
  physical RAM is non-zero.
- **ram-pct-zero-ram**: Computing a byte count's percentage of RAM MUST
  return `0` when physical RAM is `0`.

