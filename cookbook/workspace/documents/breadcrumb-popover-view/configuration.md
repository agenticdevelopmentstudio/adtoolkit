
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Directory | directory reference (URL) | — (required) | The one directory whose immediate children are loaded and listed; read once at initialization and never reloaded. |
| Selection callback | callback receiving a URL | — (required) | Invoked with a chosen file's URL when the user picks a non-directory row. |
| Cancel callback | optional callback | unset | Invoked when keyboard navigation reports cancel (Escape); typically set by the breadcrumb view after construction, since only it owns the popover. |

