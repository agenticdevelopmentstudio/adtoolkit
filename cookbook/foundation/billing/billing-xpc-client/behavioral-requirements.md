
- **failed-read-is-nil**: A list read MUST return nil when the transport fails or when any element is the read-failed sentinel row; it MUST NOT return an empty list for a failure.
- **write-result**: A write MUST return the decoded stored value on success, a refusal carrying the store's sentence when the daemon refused, `unreachable` when the call threw, and `unreadable` when the reply or the body could not be coded.
- **refusal-fallback**: A refusal with no reason MUST read "The daemon refused the change."
- **write-timeout**: Writes MUST wait 65 seconds, longer than the daemon's own 60-second write bound, and MUST NOT be retried.
- **delete-result**: A delete MUST return success, a refusal with the daemon's sentence, or `unreachable`.
- **count-result**: A count call MUST return nil when the transport fails or the count is negative (the failed-count sentinel), and the count otherwise, so zero means nothing to do.
- **overview-read**: `billingOverview` MUST return nil on any failure.
- **preferences-push**: `billingSetPreferences` MUST send the body with a 5-second timeout and no retry, and MUST return true only when the reply is non-empty.
- **default-preferences**: A service that does not implement the push MUST report every push as not applied.
- **wire-coding**: Bodies MUST be encoded with snake_case keys; replies MUST be decoded with snake_case keys and ISO-8601 dates, by one shared decoder.
- **transport-seam**: The client MUST depend only on the transport interface, not on a daemon framework.
- **entry-filters**: `billingEntries` MUST send nil filters as "any", a status as its raw string, and `since` as an ISO day.

