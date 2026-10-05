
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| permission | a permission value | none (required) | Which permission this row displays and acts on; drives the title, icon, description, and accessibility identifier. |
| checker | a status-checking dependency | none (required) | Supplies the asynchronous grant-status read that a refresh calls. |
| action handler | a callback taking a permission and a status | none (required) | Invoked when the action button is pressed, carrying the permission and the status shown at press time. |

