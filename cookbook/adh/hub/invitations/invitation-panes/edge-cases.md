
- **Null/empty input**: An empty row list on any pane is passed straight through to
  the list-with-details layout, which shows the pane's empty label; this component
  adds no special-casing of its own for an empty list. Activating "Send invitation"
  with no selected ids (only reachable by bypassing the selection requirement) seeds
  an empty email list, empty phone list, and empty id list and still opens the
  modal — the source places no additional guard on opening Send itself.
- **Boundary values**: Selecting more than one row and activating "Admin notes"
  still opens notes for only the first selected id; the remaining selected ids are
  silently ignored by that handler (Delete and Send instead act on the whole
  selected-id list).
- **Note-fallback quirk**: The Requests pane's note line uses an empty-or-falsy
  check, so an empty-string note renders "—". The Pending Users pane's note line
  uses a null-only check, so an empty-string note renders as blank, not "—" — the
  two panes are NOT symmetric here even though their detail layout looks the same.
- **Remount-key collision**: the send-invitation modal's fresh-instance identity is
  built from the seed's joined email and phone lists
  (**remounts-send-modal-on-reseed**). Two different selections that resolve to
  the same email/phone set — or two selections that both have no email and no
  phone at all — produce the same identity, so the modal does not reset between
  them and stale edits from the first selection can leak into the second; the
  source places no additional disambiguator (e.g. the seed's id list) in that
  identity.
- **Error states**: The one error path the source defines is the send callback
  rejecting: the rejection reason is discarded entirely — no error message, log,
  or re-throw — and only leaves the modal open (see
  **keeps-send-modal-open-on-reject**, **reports-send-rejection-reason**, and
  Design Decisions). The delete and add callbacks are synchronous callbacks with
  no return value in this component; it performs no error handling around them,
  so any failure handling for those two happens in the caller's own
  implementation, outside this component.
- **Concurrent access**: Not applicable — traced. The admin-notes target id, the
  send-modal and add-modal open flags, and the send seed are single-writer state
  values updated only from this component's own event handlers on the main
  thread; this component defines no shared or cross-session mutable state.
- **Offline/disconnected state**: Not applicable — traced. This component performs
  no network access itself (per its own doc comment, "the shared blocks never
  fetch"); rows and the delete/send/add callbacks are all caller-supplied, so
  connectivity handling belongs entirely to the caller.

