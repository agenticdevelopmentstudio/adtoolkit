
### Types

- **indicator-state-union**: The sign-state value MUST be exactly one of `"ok"`, `"warn"` or `"down"`.
- **indicator-shape**: An indicator value MUST carry a sign state and a count (a whole number).

### Problems-to-indicator operation

- **indicator-signature**: The problems-to-indicator operation MUST take a list of problems and MUST return an indicator value.
- **indicator-count**: The returned count MUST equal the number of problems given.
- **indicator-empty-ok**: For an empty list the operation MUST return sign state `"ok"` with count `0`.
- **indicator-critical-down**: When at least one problem has severity `"critical"`, the operation MUST return sign state `"down"`.
- **indicator-otherwise-warn**: When the list is non-empty and no problem has severity `"critical"` (only `"major"` and/or `"minor"`), the operation MUST return sign state `"warn"`.
- **indicator-server-parity**: On any problem set, the problems-to-indicator operation MUST produce the sign state that results from translating the server's own indicator rule through the wire-indicator translation map, with a count equal to the number of problems given. The doc comment calls it "a rendering projection of severities the server already assigned — not a second opinion"; a parity test pins the two on empty, minor-only, major-only and critical-bearing sets.
- **indicator-filtered-input**: The operation MUST judge only the problems it is given. A caller applying an active filter passes only the filtered subset of problems; otherwise a caller uses the server's own indicator, translated through the wire-indicator translation map directly.

### Wire-indicator translation map

- **indicator-map-values**: The wire-indicator translation map MUST map `operational` to `"ok"`, `degraded` to `"warn"` and `outage` to `"down"`.
- **indicator-map-exhaustive**: The wire-indicator translation map MUST have exactly the three keys `degraded`, `operational` and `outage` — one per member of the server's wire-level indicator vocabulary, with no extras.
- **indicator-map-sole-translation**: The wire-indicator translation map MUST be the only place that translates the wire indicator into a sign state; the doc comment names it "The ONLY translation between the two."

### Deploy-counts operation

- **counts-signature**: The deploy-counts operation MUST take a list of activity rows and a window-start time, and MUST return a build count, a deploy count and a failure count.
- **counts-deploy-kind-only**: Rows whose kind is not `"deploy"` (`"probe"`, `"platform"`) MUST NOT contribute to any count.
- **counts-window-cutoff**: A deploy row whose parsed timestamp is strictly earlier than the window-start time MUST NOT contribute to any count; a row exactly at the window-start time MUST be counted.
- **counts-builds**: Each counted row with step `"build"` MUST add 1 to the build count.
- **counts-deploys**: Each counted row with step `"deploy"` MUST add 1 to the deploy count.
- **counts-null-step**: A counted row with no step MUST add to neither the build count nor the deploy count.
- **counts-failures**: Each counted row with tone `"bad"` MUST add 1 to the failure count, independently of its step, so a failed build row counts as one build and one failure.
- **counts-server-window**: The caller MUST pass the board's own activity-window start as the window-start time; the doc comment states "the client never picks the window".
- **counts-no-rejudging**: The operation MUST read a row's step and tone as they arrive on the wire and MUST NOT recompute them.

### Activity-window-caption operation

- **window-signature**: The activity-window-caption operation MUST take a window-start time and a window-end time and MUST return a text caption.
- **window-hours**: The operation MUST compute the span in hours as the duration between the two times divided by 3,600,000 (milliseconds per hour), rounded to the nearest whole number, with a minimum of 1.
- **window-days**: When the hour count is 48 or more and is a whole multiple of 24, the operation MUST return the caption formed by dividing the hour count by 24 followed by the letter `d` (for example `"7d"`).
- **window-hours-label**: Otherwise the operation MUST return the caption formed by the hour count followed by the letter `h` (for example `"24h"`, `"47h"`).
- **window-min-one-hour**: A window shorter than 30 minutes, zero, or negative MUST be captioned `"1h"`, never `"0h"`.
- **window-server-boundary**: The caller MUST derive both bounds from the board's own reported activity window rather than a hardcoded span; the doc comment forbids a hardcoded caption because the server owns the window's length.

### Headline operation

- **headline-signature**: The headline operation MUST take a sign state and a count and MUST return a text headline.
- **headline-ok**: For sign state `"ok"` the operation MUST return `"ALL SYSTEMS OPERATIONAL"`, ignoring count.
- **headline-warn-singular**: For sign state `"warn"` and count `1` it MUST return `"1 SERVICE NEEDS ATTENTION"`.
- **headline-warn-plural**: For sign state `"warn"` and any other count it MUST return the count followed by `" SERVICES NEED ATTENTION"`.
- **headline-down-singular**: For sign state `"down"` and count `1` it MUST return `"1 PROBLEM"`.
- **headline-down-plural**: For sign state `"down"` and any other count it MUST return the count followed by `" PROBLEMS"`.
- **headline-single-wording**: Every surface that announces the sign's headline (hero sign, top-bar pill accessible name, wallboard pill) MUST obtain it from the headline operation, so they cannot word it differently. An "unknown" state is outside the sign-state vocabulary; callers word that case themselves (for example, showing "Status unknown" or "UNKNOWN").

### Real-environment-deploy predicate

- **real-env-row-signature**: The platform/environment form of the predicate MUST take a platform identifier and an environment value (which may be absent) and MUST return true or false.
- **real-env-vercel-preview**: The predicate MUST return `false` when the platform is `"vercel"` and the environment is absent or the empty string.
- **real-env-vercel-target**: The predicate MUST return `true` when the platform is `"vercel"` and the environment is any non-empty string.
- **real-env-other-platforms**: The predicate MUST return `true` for every platform other than the exact string `"vercel"`, whatever the environment is (including absent).
- **real-env-dto-delegates**: The record form of the predicate MUST return the same result as the platform/environment form, applied to a deployment record's own platform and environment fields.
- **real-env-case-sensitive**: The platform comparison MUST be exact and case-sensitive; `"Vercel"` is treated as a non-Vercel platform.
- **real-env-server-agreement**: The doc comment says the predicate is "Shared so the issue recorder and the UI can never disagree", but the server maintains its own textual copy of the same predicate, and the client's copy has no caller in the client outside this module's own test. No parity check pins the two copies (unlike the problems-to-indicator operation). A port keeps one definition that the server and the UI both use.

### Purity and concurrency

- **pure-functions**: Every exported operation MUST be synchronous and pure: no I/O, no logging, no mutation of its inputs, no module state. The result depends only on the arguments.
- **no-throw**: No operation throws on inputs of its declared shapes; malformed values degrade as described under Edge Cases rather than raising.
- **single-threaded**: The module holds no state, so calls cannot interleave and no ordering rule is needed.

