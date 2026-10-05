
- **cached-state**: The model MUST expose clients, projects, running timers, recent segments (last 14 days, at most 500), the overview, `lastError` and `lastUpdated`, and MUST publish a change signal whenever visible state changes.
- **refresh-all**: `refresh` MUST read clients, projects, running timers, recent segments and the overview concurrently, and replace the cached state only when the first four succeeded.
- **sticky-failure**: If any of the four required reads fails, the model MUST keep the last good lists, set `lastError` to the unreachable sentence, and signal only when the error is new or the caller asked to be told of unchanged results.
- **overview-fails-alone**: A failed overview read MUST keep the last good overview and MUST NOT count as a failed refresh.
- **quiet-when-unchanged**: A poll that finds nothing changed MUST NOT signal; an explicit refresh MUST signal.
- **write-generation**: A refresh MUST discard its answers if any write began while it was reading; the write's own refresh follows.
- **writes-refresh**: Every write (save and delete of clients, projects, repos, entries; set status; set description; start and stop timer; promote; assign; backfill) MUST be followed by a refresh.
- **refusal-in-last-error**: A refused write MUST return nil (or false for a delete) and leave the refusal sentence in `lastError` after the refresh, which would otherwise clear it.
- **success-clears-error**: A successful refresh MUST clear `lastError`.
- **consumer-aware-poll**: A scheduled poll MUST read everything when any consumer reports it is showing (and always on the first pass), and otherwise read only the running timers.
- **consumer-lifetime**: A consumer registration MUST be dropped when its owner is released or it is removed explicitly.
- **consumer-shown**: When a consumer is shown and the data is older than the interval, the model MUST refresh at once.
- **assign-and-roll**: `assignAndRoll` MUST assign the segments, then promote them with one refresh; when the assignment moves nothing for a non-empty list it MUST set `lastError` to the already-on-a-billable sentence and return nil.
- **refresh-interval**: The poll interval MUST default to 30 seconds.
- **lookups**: `projectName(for:)` MUST return the project's display title or `Unassigned` when none; `activeSorted` MUST drop archived projects and sort by display title using the localized standard comparison.
- **timestamps**: `date(iso:)` MUST parse an ISO-8601 UTC instant with or without fractional seconds and return nil for an empty string.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

