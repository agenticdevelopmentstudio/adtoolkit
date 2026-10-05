
### Requests Pane

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rows` | list of request records | — | Rows to render. |
| `loading` | boolean, optional | falsy | Shows the loading placeholder instead of the list. |
| `onDelete` | callback taking the array of selected ids | — | Forwarded to the list-with-details layout's delete handling. |
| `paramKey` | string, optional | none | Forwarded to the list-with-details layout for URL-based selection deep-linking. |
| `renderNotesAndHistory` | callback taking the subject table and id, returning renderable content | — | Fills the row detail panel below Source/Note. |
| `renderNotesModal` | callback taking the subject table, id, open flag, and a close handler, returning renderable content | — | Supplies the admin-notes modal. |

### Pending Users Pane

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rows` | list of pending-user records | — | Rows to render. |
| `loading` | boolean, optional | falsy | Shows the loading placeholder instead of the list. |
| `onDelete` | callback taking the array of selected ids | — | Forwarded to the list-with-details layout's delete handling. |
| `onSend` | callback taking the send payload, returning a promise | — | Called on Send; modal closes only on resolve. |
| `onAdd` | callback taking the list of drafted users | — | Forwarded to the add-users modal's add handling. |
| `sendBusy` | boolean, optional | none | Forwarded to the send-invitation modal's busy state. |
| `addBusy` | boolean, optional | none | Forwarded to the add-users modal's busy state. |
| `paramKey` | string, optional | none | Forwarded to the list-with-details layout for URL-based selection deep-linking. |
| `renderNotesAndHistory` | callback taking the subject table and id, returning renderable content | — | Fills the row detail panel below Source/Note. |
| `renderNotesModal` | callback taking the subject table, id, open flag, and a close handler, returning renderable content | — | Supplies the admin-notes modal. |

The send-invitation modal and the add-users modal are mounted with no title
override, so each keeps its own default ("Send invitation" / "Add users").

### Invites Pane

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rows` | list of invite records | — | Rows to render. |
| `loading` | boolean, optional | falsy | Shows the loading placeholder instead of the list. |
| `onDelete` | callback taking the array of selected ids | — | Forwarded to the list-with-details layout's delete handling. |
| `paramKey` | string, optional | none | Forwarded to the list-with-details layout for URL-based selection deep-linking. |
| `renderNotesAndHistory` | callback taking the subject table and id, returning renderable content | — | Supplies the entire detail panel. |
| `renderNotesModal` | callback taking the subject table, id, open flag, and a close handler, returning renderable content | — | Supplies the admin-notes modal. |

Shared shapes: the notes render-prop slots (`renderNotesAndHistory`,
`renderNotesModal`, used by all three panes) and the send payload (the shared
send-invitation payload shape extended with the selected pending-user ids), the shape
the Pending Users pane hands to its send callback.

