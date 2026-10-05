
- **shows-loading-placeholder**: While the loading flag is true, each pane MUST
  render the text "Loading…" instead of the list-with-details layout.
- **delegates-list-rendering**: While the loading flag is not true, each pane MUST
  render the list-with-details layout configured with that pane's fixed columns,
  rows, row-id accessor, accessible name, empty label, and storage key (see
  Appearance for the exact per-pane values).
- **pending-null-dates-render-dash**: The Pending Users pane's "Last request" and
  "Last invite" columns MUST render "—" when the row's value for that field is
  `null`, and the raw value otherwise.
- **forwards-param-key**: Each pane MUST forward its deep-linking selection key
  unchanged to the list-with-details layout.
- **forwards-delete-callback**: Each pane MUST forward its delete callback to the
  list-with-details layout's delete handling unchanged.
- **shows-delete-confirm-copy**: Each pane MUST show a fixed delete-confirmation
  title/description in the list-with-details layout's delete confirmation:
  Requests — "Delete requests?" / "This removes the selected invitation requests.";
  Pending Users — "Delete pending users?" / "This removes the selected pending
  users."; Invites — "Delete invites?" / "This removes the selected sent invites."
- **notes-action-requires-selection**: The "Admin notes" toolbar action MUST
  require a non-empty selection.
- **notes-action-sets-first-selected-id**: Activating "Admin notes" MUST set the
  pane's admin-notes target id to the first id among the ids the action was
  activated with, or to none when there were no selected ids.
- **gates-notes-modal-on-existing-row**: The notes modal MUST be shown open only
  while a row whose id matches the admin-notes target id is still present among
  the pane's rows, and MUST be shown closed otherwise (including while no target
  id is set).
- **resets-notes-id-on-modal-close**: Closing the notes modal MUST clear the
  admin-notes target id.
- **passes-required-aria-label**: Each pane MUST give the list-with-details layout
  a fixed, non-empty accessible name: "Invitation requests" (Requests), "Pending
  users" (Pending Users), "Sent invites" (Invites).
- **requests-and-pending-show-source-and-note**: The Requests pane's detail panel
  MUST render "Source:" followed by the row's `source` field, then "Note to the
  team:" followed by the row's `note` field, above the notes/history content. The
  Pending Users pane's detail panel MUST render "Source:" followed by the row's
  `lastSource` field, then "Note from user:" followed by the row's `lastNote`
  field, above the notes/history content.
- **invites-detail-is-notes-only**: The Invites pane's detail panel MUST render
  exactly the notes/history content for that row's subject, with no additional
  fields.
- **send-action-requires-selection**: The Pending Users pane's "Send invitation"
  toolbar action MUST require a non-empty selection.
- **send-seed-filters-selected-rows**: Activating "Send invitation" MUST derive
  its seed from exactly the rows whose id is among the ids the action was
  activated with.
- **send-seed-collects-non-empty-emails**: The send seed's email list MUST be
  those selected rows' email values with empty-string values removed.
- **send-seed-collects-non-empty-phones**: The send seed's phone list MUST be
  those selected rows' phone values with empty-string values removed.
- **send-seed-carries-selected-ids**: The send seed's id list MUST be exactly the
  ids the action was activated with (not filtered against the pane's current
  rows).
- **send-action-opens-modal**: Activating "Send invitation" MUST open the
  send-invitation modal.
- **remounts-send-modal-on-reseed**: The send-invitation modal MUST be treated as
  a fresh instance whenever the send seed's joined email and phone lists change,
  resetting any in-progress edits.
- **closes-send-modal-only-on-resolve**: The Pending Users pane's send handling
  MUST call the caller's send callback with the send payload plus the seed's id
  list, and MUST close the send-invitation modal only when that call's returned
  promise resolves.
- **keeps-send-modal-open-on-reject**: When the caller's send callback's promise
  rejects, the handler MUST leave the send-invitation modal's open state
  unchanged (it stays open) and MUST NOT throw or propagate the rejection.
- **reports-send-rejection-reason**: When the caller's send callback's promise
  rejects, the handler SHOULD surface the rejection reason — in the modal or back
  to the caller — rather than discarding it silently. The current implementation
  discards it (see Edge Cases and Design Decisions); this requirement stays unmet
  until that is settled.
- **add-action-has-divider**: The Pending Users pane's "Add users" toolbar action
  MUST render with a divider before it.
- **add-action-opens-modal**: Activating "Add users" MUST open the add-users
  modal.
- **forwards-onadd**: The Pending Users pane MUST forward its add callback to the
  add-users modal's add handling unchanged.
- **forwards-send-busy**: The Pending Users pane MUST forward its send-busy
  indicator to the send-invitation modal's busy state unchanged.
- **forwards-add-busy**: The Pending Users pane MUST forward its add-busy
  indicator to the add-users modal's busy state unchanged.

