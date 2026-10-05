
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Project root | URL | required, set at init | The project root that crumb titles and directories are computed relative to. It is fixed at initialization and cannot be changed afterward. |
| Open file | URL (optional) | none | The file the strip currently describes. Setting it recomputes and rebuilds the crumbs (**rebuild-on-every-file-assignment**); clearing it clears the strip (**clear-strip-when-file-nil**). |
| Selection callback | optional callback receiving a URL | none | Invoked with a URL — the file a popover's user chose, or the crumb's own directory when a crumb is selected by index directly. |
| Crumb titles | list of strings (read-only) | empty list | The crumb labels, root to leaf; empty when there is no file. |
| Select crumb by index | operation | n/a | Reports the directory of the crumb at a given index through the selection callback, exactly as if that crumb's popover had opened and its listener acted on the directory itself; an out-of-range index is ignored. |

