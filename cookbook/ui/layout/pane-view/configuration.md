
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stateStore` | State store | An ephemeral (in-memory) state store | Where the pane persists its minimize edge, zoomed flag, and spacing override; injected at construction. |
| `host` | Host reference (optional, held weakly) | None | The container the pane sends close/minimize/zoom/restore requests to and asks for available minimize edges and close permission. |
| `clampsToContainer` | Boolean | `false` | When `true`, yields the title bar's — and any later-installed chrome's — width demand to the container instead of asking for its own; one-way once set. |
| `onSelectionChange` | Callback (no arguments, optional) | None | Called when the content's selection description changes, for a host that shows a display path. |
| `onTitleChange` | Callback (no arguments, optional) | None | Called when the pane's resolved title would now answer differently, for a host that names the pane elsewhere (e.g. a window footer). |

