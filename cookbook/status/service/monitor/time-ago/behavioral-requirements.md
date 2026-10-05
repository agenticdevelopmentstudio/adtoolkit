
### timeAgo

- **elapsed-seconds-computation**: `timeAgo(iso, nowMs)` MUST compute `diffMs` as
  `nowMs - new Date(iso).getTime()` and `diffSecs` as `Math.floor(diffMs / 1000)`, and MUST
  select its return value from `diffSecs` and the successive floor-divisions of it, never
  from `diffMs` directly.
- **just-now-bucket**: `timeAgo` MUST return the literal string `just now` whenever
  `diffSecs` is strictly less than `60`; because the comparison is unconditional, this
  range covers every value from `0` through `59` and every negative `diffSecs` as well.
- **minutes-bucket**: `timeAgo` MUST return the string formed by `diffMins` followed by the
  literal letter `m` (`` `${diffMins}m` ``), where `diffMins` is `Math.floor(diffSecs / 60)`,
  whenever `diffSecs` is `60` or greater and `diffMins` is strictly less than `60`.
- **hours-bucket**: `timeAgo` MUST return the string formed by `diffHours` followed by the
  literal letter `h` (`` `${diffHours}h` ``), where `diffHours` is
  `Math.floor(diffMins / 60)`, whenever `diffMins` is `60` or greater and `diffHours` is
  strictly less than `24`.
- **days-bucket**: `timeAgo` MUST return the string formed by `Math.floor(diffHours / 24)`
  followed by the literal letter `d` (`` `${Math.floor(diffHours / 24)}d` ``) whenever
  `diffHours` is `24` or greater; this bucket has no upper bound — an elapsed time of ten
  years MUST still be returned as a single `d`-suffixed number (approximately `3650d`)
  rather than switching to a week/month/year unit.
- **bucket-evaluation-order**: `timeAgo` MUST evaluate the four buckets in the fixed order
  seconds → minutes → hours → days and MUST return on the first threshold satisfied,
  never evaluating a later bucket once an earlier one has matched.
- **no-suffix-composition**: `timeAgo` MUST NOT append `"ago"`, a plural suffix, or any
  separator to the unit letter; its return value is exactly the numeric bucket value
  immediately followed by `m`, `h`, or `d` with no space, or the fixed literal `just now`.
  Composing a sentence such as `"last {value} ago"` (per `integrations.ts`) or
  `"live build {value} old"` (per `fetch-vercel-projects.ts`) is each caller's own concern,
  external to this file.
- **caller-supplied-clock**: `timeAgo` MUST take its notion of "now" exclusively from its
  `nowMs` argument and MUST NOT call `Date.now()` or read the system clock internally;
  per the source's own doc comment, `nowMs` "is passed in for testability."
- **synchronous-purity**: `timeAgo` MUST execute synchronously and MUST compute its result
  deterministically from `iso` and `nowMs` alone, performing no I/O, no logging, and no
  mutation of either argument.
- **no-throw-on-well-formed-input**: `timeAgo` MUST NOT throw for any `iso` string that
  `new Date` parses to a valid timestamp and any finite `nowMs` number; every branch it can
  take returns a string value.
- **no-iso-validation**: `timeAgo` expects its caller to pass a parseable ISO-8601 timestamp, as its parameter name `iso` states, and does not validate it. When `new Date(iso).getTime()` returns `NaN`, every threshold comparison evaluates `false`, the function falls through to the days branch and returns the literal string `'NaNd'`. It never throws. Both callers (`integrations.ts` and `fetch-vercel-projects.ts`) build `iso` with `Date.prototype.toISOString()`, which throws on an invalid date, so neither can pass it a malformed string.

