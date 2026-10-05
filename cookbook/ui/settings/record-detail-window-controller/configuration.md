
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| window id | text | none (required) | The identity of the window |
| title | text | none (required) | The window title |
| accessibility prefix | text | none (required) | Prefix for the add and remove control identifiers |
| pane factory | function of record | none (required) | Builds a pane for a record seen for the first time |
| pane updater | function of pane and record | none (required) | Hands a pane its record's current values |
| empty message | optional text | none | Shown beside the controls while the list is empty |
| can-remove check | optional function of record | none (every record removable) | Vetoes removal |

