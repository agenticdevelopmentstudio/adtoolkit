
- **Null/empty input**: A blank or whitespace-only search query is answered
  with an empty result without a network call
  (search-blank-query-short-circuits). An empty key-prefix input is refused
  with `"A key prefix is required."`, never treated as "clear the prefix"
  (project-key-prefix-empty-refused-not-cleared). A milestone with `null`
  counts MUST render as "unknown", never as a zeroed progress bar
  (milestone-progress-null-when-counts-absent).
- **Boundary/malformed values**: A key-prefix input of exactly 2 or 8
  characters MUST be accepted; 1 or 9 characters MUST be rejected
  (hub-domain-projects-006/008). A move target naming neither neighbor, or
  explicitly nulling both, is a 400 — "nothing above and nothing below...
  is never the move anyone meant" (work-item-move-by-named-neighbor). A
  "before" activity cursor with no separator (a legacy token) is still
  accepted, sent as the timestamp alone
  (activity-legacy-token-without-id-still-works).
- **Concurrent access**: Two closely-timed link calls for the same
  (direction, target kind, target id) triple — the second returns the
  existing row rather than creating a duplicate
  (artifact-link-idempotent-per-triple). Two closely-timed accept calls on
  the same card — the second applies its placement but does not disturb
  the original triage timestamp (triage-accept-idempotent-on-stamp). Two
  clients moving cards with the same named neighbor both land beside it,
  deliberately avoiding the race an index-based move would create ("two
  clients sending \"index 3\" race, whereas two clients naming the same
  neighbour both land beside it"). A pending coalesced wake outlived by an
  unmounting subscriber is dropped rather than firing against a gone
  component (live-unsubscribe-during-pending-wake-is-silent,
  live-last-unsubscribe-drops-pending-timer).
- **Error states**: Every single-item fetch across every grouping (boards,
  iterations, programs, cards) resolves to `null` on a thrown 404 rather
  than rethrowing (project-get-null-on-not-found and its analogues per
  grouping). Updating a status update by anyone but the report's author is
  a 403 (status-update-edit-gated-by-authorship); editing a comment by
  anyone but the comment's author is likewise refused
  (comment-edit-gated-by-authorship).
- **Ownership / scoping mismatches**: A milestone id from a board other
  than the one addressed is a 404, never a cross-board edit
  (milestone-owned-by-project). A program from another workspace named as a
  board's program id is a 400. An iteration's owner must match the
  committing card's board's owner.

