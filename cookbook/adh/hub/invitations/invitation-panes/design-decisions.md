
**Decision**: `SendInvitationModal` closes only when the caller's `onSend` promise
resolves; on rejection it stays open and the rejection reason is discarded.
**Rationale**: per the source's own comment, this keeps the failure visible to the
admin (the modal does not vanish) and keeps the send retryable, at the cost of
not surfacing the actual error to the admin or to any log.
**Approved**: pending

**Decision**: `SendInvitationModal` is remounted via a `key` built from the joined
seed emails and phones, rather than reseeded through props alone.
**Rationale**: forces the modal's internal recipient/note state to reset whenever a
new selection opens Send, instead of leaking a stale selection's edits into the
next one.
**Approved**: pending

**Decision**: the "Admin notes" modal's `open` is derived from
`rows.find(row => row.id === notesForId) != null` rather than from
`notesForId != null` directly.
**Rationale**: prevents the modal from opening for a `notesForId` that no longer
names a row present in `rows` — e.g. the row was deleted or filtered out
between selecting notes and the modal's render.
**Approved**: pending

**Decision**: `InvitationInvitesPane`'s detail panel renders only
`renderNotesAndHistory`, while `InvitationRequestsPane`'s and
`InvitationPendingUsersPane`'s detail panels prepend their own Source/Note
fields.
**Rationale**: traced directly to the source — a sent invite's row already exposes
name/email/sentBy/sentDate as table columns, leaving nothing pane-specific for
the detail panel beyond notes/history, unlike a request or pending user, which
carry a `source`/note field that is not itself a table column.
**Approved**: pending

**Decision**: `InvitationRequestsPane`'s note fallback uses `r.note || "—"` while
`InvitationPendingUsersPane`'s uses `u.lastNote ?? "—"`.
**Rationale**: not stated in the source; this reads as an inconsistency between two
otherwise parallel detail panels rather than a deliberate design choice (see
Edge Cases, "Note-fallback quirk"). Documented here as a known discrepancy
rather than idealized away.
**Approved**: pending

