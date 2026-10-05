
This is the group of three sibling panes covering one stage each of the Invitations
workflow: incoming requests, pending users awaiting an invite, and sent invites (the
Requests pane, the Pending Users pane, and the Invites pane, respectively). Each is
built on a shared master-detail list-with-details layout
(agenticdevelopertoolkit://recipes/list-with-details-pane) configured with pane-specific
columns, an empty label, a storage key, and a shared "Admin notes" toolbar action. The
Pending Users pane additionally offers "Send invitation" and "Add users" actions that
open the send-invitation modal
(adtoolkit://cookbook/adh/hub/invitations/send-invitation-modal) and the add-users
modal (agenticdevelopertoolkit://recipes/add-users-modal).

None of the three panes fetch data, persist anything, or own the notes/history UI:
rows, the delete/send/add callbacks, and the notes render-prop slots (a
notes-and-history renderer and a notes-modal renderer) are all supplied by the caller,
because — per the source's own doc comment — "the shared blocks never fetch." This
recipe documents only what these three panes themselves do; the visual chrome,
keyboard behavior, and accessibility contract of the list-with-details layout, the
send-invitation modal, and the add-users modal are each documented in their own recipe
and are not restated here.

Each pane calls its notes renderers with a fixed subject-table identifier, one of
three string constants: `"invitation_requests"` (Requests), `"pending_users"`
(Pending Users), and `"invitations"` (Invites).

