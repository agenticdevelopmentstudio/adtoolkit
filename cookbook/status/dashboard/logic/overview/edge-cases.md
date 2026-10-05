
- **Empty problem list**: The problems-to-indicator operation on an empty list MUST return sign state `"ok"`, count `0`. A caller guards the case where "ok" would be a false "ALL SYSTEMS OPERATIONAL" claim (for example, no data yet loaded); the module itself does not.
- **Unknown severity**: A problem whose severity is none of the recognized values counts toward the count and MUST yield `"warn"` unless another problem has severity `"critical"`.
- **Empty activity**: The deploy-counts operation on an empty list, for any window-start time, MUST return all counts as zero.
- **Unparseable time stamp**: An unparseable row time stamp is treated as no less than the window-start time (an invalid-time comparison is never true), so the row MUST be counted as inside the window. A row's time field is documented as an ISO-8601 time supplied by the server, so this is a caller precondition, not validation the module performs.
- **Invalid window-start time**: If the window-start time itself is invalid, every comparison against it is false, so every deploy row MUST be counted.
- **Non-integer or huge windows**: The activity-window-caption operation rounds to the nearest hour (for example 23.6h to `"24h"`); a whole-day multiple of 48h or more MUST switch to days, and 24h MUST stay `"24h"`.
- **Invalid bounds**: If either bound given to the caption operation is invalid (for example from an unparseable time stamp upstream), the reference implementation performs no guard and returns the caption `"NaNh"`; a port whose numeric type has no equivalent invalid-number propagation should pick its own fallback (see Platform Notes).
- **Negative or zero window**: The activity-window-caption operation MUST return `"1h"`.
- **Headline with count 0 and a non-ok state**: The headline operation MUST return `"0 SERVICES NEED ATTENTION"` or `"0 PROBLEMS"`; the operation trusts the caller's pairing of state and count.
- **Negative or fractional count**: The headline operation MUST interpolate it verbatim with the plural form (for example `"-1 PROBLEMS"`).
- **Vercel environment of whitespace**: The platform/environment form of the predicate on platform `"vercel"` and environment `" "` (a single space) MUST return `true`; only an absent environment or the empty string count as a preview.
- **Concurrent access**: Not applicable. The module is stateless, so calls cannot interleave.
- **Error states and offline**: Not applicable. The module performs no I/O; a missing or stale board is handled by its callers, which map it to an "unknown" state before the wire-indicator translation map is consulted.

