
The source hardcodes every user-facing string directly; there is no i18n key or
translation lookup anywhere in this component's source.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `loading-message` | "Loading…" | Loading placeholder (all panes) |
| `admin-notes-action` | "Admin notes" | Toolbar action label (all panes) |
| `send-invitation-action` | "Send invitation" | Toolbar action label (Pending Users only) |
| `add-users-action` | "Add users" | Toolbar action label (Pending Users only) |
| `requests-empty-label` | "No invitation requests." | Empty label (Requests) |
| `pending-empty-label` | "No pending users." | Empty label (Pending Users) |
| `invites-empty-label` | "No invites sent." | Empty label (Invites) |
| `requests-delete-confirm-title` | "Delete requests?" | Delete-confirmation title (Requests) |
| `requests-delete-confirm-description` | "This removes the selected invitation requests." | Delete-confirmation description (Requests) |
| `pending-delete-confirm-title` | "Delete pending users?" | Delete-confirmation title (Pending Users) |
| `pending-delete-confirm-description` | "This removes the selected pending users." | Delete-confirmation description (Pending Users) |
| `invites-delete-confirm-title` | "Delete invites?" | Delete-confirmation title (Invites) |
| `invites-delete-confirm-description` | "This removes the selected sent invites." | Delete-confirmation description (Invites) |
| `column-name` | "Name" | Column header, shared by all three panes |
| `column-phone` | "Phone" | Column header, shared by Requests and Pending Users |
| `column-email` | "Email" | Column header, shared by all three panes |
| `column-user-number` | "User #" | Column header (Requests only) |
| `column-requested` | "Requested" | Column header (Requests and Pending Users) |
| `column-invited` | "Invited" | Column header (Pending Users only) |
| `column-request-count` | "Requests" | Column header (Pending Users only) |
| `column-last-request` | "Last request" | Column header (Pending Users only) |
| `column-last-invite` | "Last invite" | Column header (Pending Users only) |
| `column-sent-by` | "Sent by" | Column header (Invites only) |
| `column-sent` | "Sent" | Column header (Invites only) |
| `requests-source-label` | "Source:" | Detail label, Requests (`source`) |
| `requests-note-label` | "Note to the team:" | Detail label, Requests (`note`) |
| `pending-source-label` | "Source:" | Detail label, Pending Users (`lastSource`) |
| `pending-note-label` | "Note from user:" | Detail label, Pending Users (`lastNote`) |
| `empty-value-dash` | "—" | Fallback text for a null/empty `lastRequestDate`, `lastInviteSentDate`, or `note`/`lastNote` (see Edge Cases for the two panes' differing fallback rule) |

