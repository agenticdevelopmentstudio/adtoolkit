
This component renders no corner radius, padding, background, border, or shadow of
its own. It does apply a small, fixed set of neutral typography/foreground-color
roles directly — no raw hex values, no important-tagged overrides: the loading text
uses a small font size and the dimmed-text color role; the Requests and Pending Users
panes' detail panels wrap their Source/Note lines in a small-font-size block using the
default text color role, with the muted-text color role on the "Source:"/"Note …:"
label spans, and a small top margin above the note line. The Invites pane's detail
panel applies none of these — it renders the notes/history content directly, with no
wrapper. Everything else is delegated to the list-with-details layout, the
send-invitation modal, and the add-users modal, each of which owns and documents its
own corner radius, padding, typography, color, border, shadow, and sizing. What
differs between the three panes is entirely the *data* each supplies to the
list-with-details layout:

| Pane | Columns (`key` — header, width, align, notes) | Empty label | `storageKey` | Accessible name |
|---|---|---|---|---|
| Requests | `userNumber` — "User #" 6rem; `name` — "Name"; `phone` — "Phone"; `email` — "Email"; `requestedDate` — "Requested" 9rem | "No invitation requests." | `adm-inv-requests` | "Invitation requests" |
| Pending Users | `name` — "Name"; `phone` — "Phone"; `email` — "Email"; `invitedCount` — "Invited" 6rem, align end; `requestCount` — "Requests" 6rem, align end; `lastRequestDate` — "Last request" 9rem, renders `—` when null; `lastInviteSentDate` — "Last invite" 9rem, renders `—` when null; `requestedDate` — "Requested" 9rem | "No pending users." | `adm-inv-pending` | "Pending users" |
| Invites | `name` — "Name"; `email` — "Email"; `sentBy` — "Sent by"; `sentDate` — "Sent" 9rem | "No invites sent." | `adm-inv-invites` | "Sent invites" |

Every date column (`requestedDate`, `sentDate`, `lastRequestDate`,
`lastInviteSentDate`) is rendered exactly as received in the row's string field; this
component applies no formatting, truncation, or locale conversion of its own beyond
the dash fallback for a null value (see **pending-null-dates-render-dash**). The row
types declare these fields as already-formatted strings, so any date formatting
happens upstream of this component, not within it.

- **Corner radius / Padding / Background / Border / Shadow / Min-Max size**: Not
  applicable — traced. This component sets none of these itself; every such
  surface belongs to a composed component with its own recipe.
- **Font / Foreground**: traced. This component itself applies only the neutral
  typography/color roles listed above — small font size, dimmed-text,
  default-text, and muted-text color roles — no raw hex, no important-tagged
  overrides. Every other font/color surface belongs to a composed component with
  its own recipe.

