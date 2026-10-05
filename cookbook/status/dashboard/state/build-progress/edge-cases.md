
- **Empty activity**: `[]` MUST yield `visible: false`, `total: 0`, `completed: 0`, `pct: 0`, `complete: false`, and the accumulation step MUST return early without touching state.
- **Build drops out of the feed**: A cohort id missing from the next snapshot MUST count as completed; this logic cannot distinguish "finished" from "paged out" and MUST NOT try.
- **Wedged build**: A build toned `"progress"` indefinitely MUST keep the bar visible below 100% until the server re-tones the row; there is no client timeout.
- **Build re-enters progress**: A cohort id that settled and then is toned `"progress"` again MUST count as not completed again; if this happens during the hold it MUST cancel the reset.
- **New build during the hold**: A new in-flight id arriving before 2000 ms elapse MUST join the existing cohort, and `total` MUST include the already-completed builds.
- **Same id after reset**: After the cohort resets, an id seen in flight again MUST start a new cohort of one.
- **Duplicate ids in one snapshot**: They MUST collapse to one cohort member.
- **Tones other than `"progress"`**: `"good"`, `"bad"`, `"neutral"` and `"stale"` MUST all count as not in flight.
- **Malformed input**: This logic relies on the activity-row shape; it performs no runtime validation, and a row missing `kind`, `step` or `tone` MUST simply fail the in-flight predicate.
- **Environment filter changes**: If the caller's filtered array stops including a cohort build, that build MUST count as completed, exactly like a row leaving the feed.
- **Concurrent access**: Not applicable beyond the threading requirement; this logic runs without concurrent execution and each evaluation sees one snapshot (see Platform Notes).
- **Network or offline**: Not applicable; this logic does no I/O. A stale board simply keeps the last snapshot's rows, and the bar reflects them unchanged.
- **Teardown**: A pending hold timer MUST be cleared during teardown (see Platform Notes).

