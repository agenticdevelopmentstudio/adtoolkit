
- **run-shape**: A run MUST carry `startedAt`, `endedAt` and `seconds`; an empty `endedAt` marks an open run, whose `seconds` MUST be 0.
- **parse-sort-dedupe**: The string entry point MUST drop unparseable timestamps, de-duplicate by whole epoch second, and sort ascending before splitting, so out-of-order arrival never yields a negative-length run.
- **split-on-gap**: Activity MUST split into runs at every gap strictly greater than the cutoff; a gap exactly equal to the cutoff MUST NOT split. A run closes at the last event before the gap.
- **no-activity-no-runs**: With no activity the result MUST be empty.
- **single-event**: A single event MUST yield exactly one run that starts and ends at that event; it is a closed run of zero seconds unless the open-final-run rule keeps it open.
- **cutoff-default**: A cutoff of zero or less MUST be replaced by the default of 15 minutes (900 seconds).
- **first-run-lead-in**: The first run MUST start at the session start instead of its first event when the session start parses, precedes the first event, and is within the cutoff of it. Later runs MUST get no lead-in.
- **open-final-run**: The final run MUST stay open only when the session is active and `now` parses and is within the cutoff of the last event; otherwise it MUST close at the last event.
- **malformed-now-closes**: A malformed `now` MUST close the final run rather than leave it open.
- **seconds-non-negative**: A closed run's `seconds` MUST be the end minus the start, never negative.
- **caller-supplies-clock**: The derivation MUST NOT read the current time; the caller passes `now`.
- **deterministic**: The same inputs MUST produce the same runs.

