
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `registry` | the server registry | — (required) | Supplies the live client list this bar and its popover observe for the available-server list and names. |
| `activeServerIds` | two-way binding to a set of ids | — (required) | Two-way link to the caller's active-server set. Its value is read once, at construction, for the initial snapshot (see **snapshots-active-ids-at-init**), and is written to — never re-read — every time the user toggles a server. |

