
### timeAgo

- **elapsed-seconds-computation**: `timeAgo(iso, nowMs)` MUST compute `diffMs` as
  `nowMs - new Date(iso).getTime()` and `diffSecs` as `Math.floor(diffMs / 1000)`, and MUST
  choose its result from `diffSecs` and successive floor-divisions of it.
- **just-now-bucket**: `timeAgo` MUST return the literal string `just now` whenever
  `diffSecs` is strictly less than `60`, which includes every negative `diffSecs` (an `iso`
  later than `nowMs`).
- **minutes-bucket**: `timeAgo` MUST return `diffMins` immediately followed by `m`, where
  `diffMins` is `Math.floor(diffSecs / 60)`, whenever `diffSecs` is at least `60` and
  `diffMins` is strictly less than `60`.
- **hours-bucket**: `timeAgo` MUST return `diffHours` immediately followed by `h`, where
  `diffHours` is `Math.floor(diffMins / 60)`, whenever `diffMins` is at least `60` and
  `diffHours` is strictly less than `24`.
- **days-bucket**: `timeAgo` MUST return `Math.floor(diffHours / 24)` immediately followed
  by `d` whenever `diffHours` is at least `24`.
- **days-unbounded**: The days bucket MUST have no upper bound; the function MUST NOT roll
  over to a week, month or year unit (365 days returns `365d`).
- **bucket-evaluation-order**: `timeAgo` MUST test the buckets in the fixed order seconds,
  minutes, hours, days, and MUST return on the first threshold satisfied.
- **no-suffix-composition**: `timeAgo` MUST NOT append `ago`, a plural form, or a space to
  the unit letter; the result is exactly the number followed by `m`, `h` or `d`, or the
  literal `just now`. Callers compose surrounding text themselves (`Dashboard` builds
  "updated {value} ago"; `ProjectBrowser` appends " ago").
- **caller-supplied-clock**: `timeAgo` MUST take "now" only from its `nowMs` argument and
  MUST NOT read the system clock; the doc comment says `nowMs` "is passed in for
  testability."
- **synchronous-purity**: `timeAgo` MUST run synchronously and return a result determined
  by `iso` and `nowMs` alone, with no I/O, no logging, and no mutation of shared state.
- **no-throw**: `timeAgo` MUST NOT throw for any `string` `iso` and any `number` `nowMs`;
  every path returns a string.
- **iso-precondition**: The caller MUST pass an `iso` string that `new Date` can parse, as
  the parameter name `iso` and its `string` type document; `timeAgo` does not validate it.
  When `new Date(iso).getTime()` or `nowMs` is `NaN`, every comparison is false and the
  function MUST return the literal string `NaNd`. The web callers guard only against a
  missing value (`FleetView`, `StatusMatrix` and `ProjectBrowser` test truthiness, and
  `Dashboard` uses optional chaining before calling), so a malformed API timestamp renders
  `NaNd` visibly rather than vanishing.

