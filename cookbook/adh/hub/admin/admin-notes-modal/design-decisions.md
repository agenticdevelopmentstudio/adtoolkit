
- **Decision**: Re-seed the staged working list from `notes` only when the dialog is closed,
  or when it is open and the working list still equals the value it was last seeded from.
  **Rationale**: A reopened dialog, or a background refetch landing on an untouched open
  dialog, must reflect the freshest loaded notes — but a background refetch must never
  silently overwrite an admin's in-progress edits. Comparing against the last-seeded value
  (rather than `notes` directly) is what lets the effect distinguish "the admin hasn't
  touched anything since the last seed" from "the incoming prop changed," per the source's
  own comment on this boundary.
  **Approved**: pending
- **Decision**: A concurrent edit made by another admin during a staged local session is
  dropped by outer Save and left unresolved by this component.
  **Rationale**: The source explicitly scopes this out as a data-merge problem, distinct from
  the save-gate problem this component solves, and calls a three-way merge here "a large,
  unreviewed behaviour change" to be addressed deliberately and separately, not incidentally.
  **Approved**: pending
- **Decision**: Both dialogs discard staged state on Cancel/Escape/close with no confirmation
  prompt.
  **Rationale**: Not explained beyond the discard-and-reset implementation itself; recorded
  here as the literal, observed contract rather than an endorsed ideal, so implementations on
  other platforms match it exactly instead of assuming a confirm step exists.
  **Approved**: pending
- **Decision**: `busy` disables only the outer Save control; it does not block dismissal and
  drives no spinner or other visual indicator.
  **Rationale**: Not explained in source; captured here as the literal contract so
  other-platform implementations do not add dismissal-blocking or a spinner that the source
  does not have.
  **Approved**: pending
- **Decision**: A new note's `id` is client-generated (`note-${Date.now()}`) and submitted to
  the caller inside the same `{id, content}` shape used for existing notes.
  **Platform**: React/Web.
  **Rationale**: Keeps the outer Save payload uniform for new and existing notes; how the
  caller/backend treats a client-generated, not-yet-persisted id is outside this file and not
  observable here.
  **Approved**: pending
- **Decision**: On WinUI 3, where both list and editor views share one `ContentDialog`,
  Escape/`CloseButtonCommand` while in editor-view content must return to list-view content
  rather than close the `ContentDialog`.
  **Rationale**: The source's two-independent-dialogs structure lets Escape on the note
  editor discard only the draft (**discards-draft-on-editor-cancel**), leaving the outer
  working list untouched. A single shared `ContentDialog` has no second dialog to dismiss
  independently, so its default Escape/close handling would discard the whole working list
  instead — a structural divergence from the source that this override corrects.
  **Approved**: pending

