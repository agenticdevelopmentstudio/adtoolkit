
- **json-payloads**: Every DTO MUST cross as JSON data, snake_case keys and ISO-8601 dates.
- **write-reply-shape**: A write reply MUST be a stored-value payload (or true) plus an optional refusal sentence; a nil or false first value MUST mean nothing was written and the sentence MUST say why; the sentence MUST be nil on success.
- **list-read-failure**: A list read that failed MUST reply with the one element `BillingWire.readFailedRow`, never an empty list.
- **count-failure**: A count reply MUST be `BillingWire.failedCount` (-1) when the write threw, never 0, which means nothing to do.
- **clients-projects**: Client and project reads MUST include archived records so archived history still names its owner; deleting a client MUST detach its projects and deleting a project MUST detach its segments, never delete them.
- **entries-read**: Entries MUST be newest day first; nil `projectId`, `status` and `since` mean any; `since` is an ISO day.
- **entry-writes**: `billingSaveEntry` MUST be refused when the entry is billed or paid; `billingSetEntryStatus` MUST write an audit row and reply nil for an unknown id or status; `billingSetEntryDescription` MUST change only the description; `billingDeleteEntry` MUST reply false when the entry is locked or unknown.
- **audit-read**: `billingEntryAudit` MUST return the trail oldest first.
- **segments-read**: `billingSegments` MUST return recorded time newest first, from an ISO-8601 `since` and up to `limit`.
- **timers**: `billingStartTimer` MUST stop any other running timer first; `billingStopTimer` MUST reply the closed segment.
- **assignment**: `billingAssignSegments` and `billingAssignRepository` MUST reply how many moved; `billingPromoteSegments` how many entries were written; `billingBackfill` how many sessions were queued.
- **overview**: `billingOverview` MUST reply one encoded overview payload.
- **set-preferences**: `billingSetPreferences` MUST apply the eight knobs, reply the clamped snapshot now in force, and reply empty data when the write failed.
- **selectors-stable**: Selector names MUST NOT change, because the two sides agree by selector.

